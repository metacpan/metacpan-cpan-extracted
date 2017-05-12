package Ace::SocketServer;

require 5.004;
use strict;
use Carp 'croak','cluck';
use Ace qw(rearrange STATUS_WAITING STATUS_PENDING STATUS_ERROR);
use IO::Socket;
use Digest::MD5 'md5_hex';

use vars '$VERSION';
$VERSION = '1.01';

use constant DEFAULT_USER    => 'anonymous';  # anonymous user
use constant DEFAULT_PASS    => 'guest';      # anonymous password
use constant DEFAULT_TIMEOUT => 120;          # two minute timeout on queries

# header information
use constant HEADER => 'L5a30';
use constant HEADER_LEN => 5*4+30;
use constant ACESERV_MSGREQ   => "ACESERV_MSGREQ";
use constant ACESERV_MSGDATA  => "ACESERV_MSGDATA";
use constant WORDORDER_MAGIC => 0x12345678;

# Server only, it may just be sending or a reply or it may be sending an
# instruction, such as "operation refused".
use constant ACESERV_MSGOK     => "ACESERV_MSGOK";
use constant ACESERV_MSGENCORE => "ACESERV_MSGENCORE";
use constant ACESERV_MSGFAIL   => "ACESERV_MSGFAIL";
use constant ACESERV_MSGKILL   => "ACESERV_MSGKILL";

use constant ACESERV_CLIENT_HELLO => "bonjour";
use constant ACESERV_SERVER_HELLO => "et bonjour a vous";

sub connect {
  my $class = shift;
  my ($host,$port,$timeout,$user,$pass) = rearrange(['HOST','PORT','TIMEOUT','USER','PASS'],@_);
  $user    ||= DEFAULT_USER;
  $pass    ||= DEFAULT_PASS;
  $timeout ||= DEFAULT_TIMEOUT;
  my $s = IO::Socket::INET->new("$host:$port") || 
    return _error("Couldn't establish connection");
  my $self = bless { socket    => $s,
		     client_id => 0,  # client ID provided by server
		     timeout   => $timeout,
		   },$class;
  return unless $self->_handshake($user,$pass);
  $self->{status} = STATUS_WAITING;
  $self->{encoring} = 0;
  return $self;
}

sub DESTROY {
  my $self = shift;
  return if $self->{last_msg} eq ACESERV_MSGKILL;
  $self->_send_msg('quit');
# Is _recv_msg() bringing things down in flames?  Maybe!
  my ($msg,$body) = $self->_recv_msg('strip');
  warn "Did not get expected ACESERV_MSGKILL message, got $msg instead" 
    if defined($msg) and $msg ne ACESERV_MSGKILL;
}

sub encore { return shift->{encoring} }

sub status { shift->{status} }

sub error { $Ace::Error; }

sub query {
  my $self = shift;
  my ($request,$parse) = @_;
  warn "query($request)" if Ace->debug;
  unless ($self->_send_msg($request,$parse)) {
    $self->{status} = STATUS_ERROR;
    return _error("Write to socket server failed: $!");
  }
  $self->{status} = STATUS_PENDING;
  $self->{encoring} = 0;
  return 1;
}

sub read {
  my $self = shift;
  return _error("No pending query") unless $self->status == STATUS_PENDING;
  $self->_do_encore || return if $self->encore;
  # call select() here to time out

  if ($self->{timeout}) {
      my $rdr = '';
      vec($rdr,fileno($self->{socket}),1) = 1;
      my $result = select($rdr,undef,undef,$self->{timeout});
      return _error("Query timed out") unless $result;
  }

  my ($msg,$body) = $self->_recv_msg;
  return unless defined $msg;
  $msg =~ s/\0.+$//;  # socketserver bug workaround: get rid of junk in message
  if ($msg eq ACESERV_MSGOK or $msg eq ACESERV_MSGFAIL) {
    $self->{status}   = STATUS_WAITING;
    $self->{encoring} = 0;
  } elsif ($msg eq ACESERV_MSGENCORE) {
    $self->{status}   = STATUS_PENDING;  # not strictly necessary, but helpful to document
    $self->{encoring} = 1;
  } else {
    $self->{status}   = STATUS_ERROR;
    return _error($body);
  }
  return $body;
}

sub write {
  my $self = shift;
  my $data = shift;
  unless ($self->_send_msg($data,1)) {
    $self->{status} = STATUS_ERROR;
    return _error("Write to socket server failed: $!");
  }
  $self->{status} = STATUS_PENDING;
  $self->{encoring} = 0;
  return 1;
}

sub _error {
  $Ace::Error = shift;
  return;
}

# return socket (read only)
sub socket { $_[0]->{socket} }

# ----------------------------- low level -------------------------------
sub _do_encore {
  my $self = shift;
  unless ($self->_send_msg('encore')) {
    $self->{status} = STATUS_ERROR;
    return _error("Write to socket server failed: $!");
  }
  $self->{status} = STATUS_PENDING;
  return 1;
}
sub _handshake {
  my $self = shift;
  my ($user,$pass) = @_;
  $self->_send_msg(ACESERV_CLIENT_HELLO);
  my ($msg,$nonce) = $self->_recv_msg('strip');
  return unless $msg eq ACESERV_MSGOK;
  # hash username and password
  my $authdigest = md5_hex(md5_hex($user . $pass).$nonce);
  $self->_send_msg("$user $authdigest");
  my $body;
  ($msg,$body) = $self->_recv_msg('strip');
  return _error("server: $body") unless $body eq ACESERV_SERVER_HELLO;
  return 1;
}

sub _send_msg {
  my ($self,$msg,$parse) = @_;
  return unless my $sock = $self->{socket};
  local $SIG{'PIPE'} = 'IGNORE';
  $msg .= "\0";  # add terminating null
  my $request;
  if ($parse) {
    $request = ACESERV_MSGDATA;
  } else {
    $request = $msg eq "encore\0" ? ACESERV_MSGENCORE : ACESERV_MSGREQ;
  }
  my $header  = pack HEADER,WORDORDER_MAGIC,length($msg),0,$self->{client_id},0,$request;
  print $sock $header,$msg;
}

sub _recv_msg {
  my $self = shift;
  my $strip_null = shift;
  return unless my $sock = $self->{socket};
  my ($header,$body);
  my $bytes = CORE::read($sock,$header,HEADER_LEN);
  unless ($bytes > 0) {
    $self->{status} = STATUS_ERROR;
    return _error("Connection closed by remote server: $!");
  }
  my ($magic,$length,$junk1,$clientID,$junk2,$msg) = unpack HEADER,$header;
  $self->{client_id} ||= $clientID;
  $msg =~ s/\0*$//;
  $self->{last_msg} = $msg;
  if ($length > 0) {
    return _error("read of body failed: $!" ) 
      unless CORE::read($sock,$body,$length);
    $body =~ s/\0*$// if defined($strip_null) && $strip_null;
    return ($msg,$body);
  } else {
    return $msg;
  }
}

1;

__END__
