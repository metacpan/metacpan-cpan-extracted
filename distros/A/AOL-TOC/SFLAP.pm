package AOL::SFLAP;

use IO;
use IO::Select;
use Socket;

$VERSION = "0.33";

$SFLAP_SIGNON    = 1;
$SFLAP_DATA      = 2;
$SFLAP_ERROR     = 3;
$SFLAP_SIGNOFF   = 4;
$SFLAP_KEEPALIVE = 5;

sub register_callback {
  my ($self, $chan, $func, @args) = @_;

  #print "register_callback() func $func for chan $chan adding to $self->{callback}{$chan}\n";
  #print "                    self $self selfcb = $self->{callback}\n";

  push (@{$self->{callback}{$chan}}, $func);
  @{$self->{callback}{$func}} = @args;

  return;
}

sub clear_callbacks {
  my ($self) = @_;
  my $k;

  print "...............C SFLAP clear_callbacks\n";
  for $k (keys %{$self->{callback}}) {
    print ".............C Clear key ($k)\n";
    delete $self->{callback}{$k};
  }

  print "...............S SFLAP scan callbacks\n";
  for $k (keys %{$self->{callback}}) {
    print ".............S Scan key ($k)\n";
  }

}

sub callback {
  my ($self, $chan, @args) = @_;
  my $func;

  for $func (@{$self->{callback}{$chan}}) {
    #print ("callback() calling a func $func for $chan fd $self->{fd}..\n");
    eval { &{$func} ($self, @args, @{$self->{callback}{$func}}) };
  }

  return;
}

sub new {
  my ($tochost, $authorizer, $port, $nickname) = @_;
  my $self;
  my $ipaddr;

  if ($port =~ /\D/) { $port = getservbyname($port, 'tcp') }
  die "invalid port" unless $port;

  $ipaddr = inet_aton($tochost);
  die "unknown host" unless $ipaddr;

  $self = {
    tochost	=> $tochost,
    authorizer	=> $authorizer,
    ipaddr	=> $ipaddr,
    port	=> $port,
    nickname	=> $nickname,
    sequence    => 1
  };
  bless($self);

  return $self;
}

sub destroy {
  my ($self) = @_;

  print "sflap destroy\n";
  CORE::close($self->{fd});

  $self = undef;

  return;
}

sub close {
  my ($self) = @_;
  my $k;

  print "sflap close\n";

  $self->clear_callbacks();

  #CORE::close($self->{fd});

  return;
}

sub set_debug {
  my ($self, $level) = @_;

  $self->{debug_level} = $level;
  print "slfap debug level $level\n";
}

sub debug {
  my ($self, @args) = @_;

  if (exists $self->{debug_level} && $self->{debug_level} > 0) {
    print @args;
  }
}

sub __connect {
  my ($self) = @_;
  my $socksaddr = inet_aton("206.223.45.1");

  my $proto = getprotobyname('tcp');
  my $sin   = sockaddr_in(1080, $socksaddr);
  my $fd    = IO::Handle->new();
 
   socket($fd, PF_INET, SOCK_STREAM, $proto) || die "socket: $!";
  connect($fd, $sin) || die "connect: $!";

  $buffer = pack("ccncccca*c", 4, 1, 443, 198, 81, 3, 52, "jamersepoo", 0);
  syswrite($fd, $buffer, 19);

  return ($fd);
}

sub _connect {
  my ($self) = @_;

  my $proto = getprotobyname('tcp');
  my $sin   = sockaddr_in($self->{port}, $self->{ipaddr});
  my $fd    = IO::Handle->new();

   socket($fd, PF_INET, SOCK_STREAM, $proto) || die "socket: $!";
  connect($fd, $sin) || die "connect: $!";

  return ($fd);
}

sub connect {
  my ($self) = @_;
  my $fd;

  if ($self->{proxy}) {
    $fd = &{$self->{proxy}};
  } else {
    $fd = $self->_connect;
  }

  $self->{fd} = $fd;

  $foo = $self->write("FLAPON\r\n\r\n", 10);

  $self->recv();

  return $fd;
}

sub recv {
  my ($self) = @_;
  my ($buffer, $from, $xfrom) = '';
  my ($fd) = $self->{fd};

  $foo = CORE::sysread($fd, $buffer, 6);
  if ($foo <= 0) {
    #print "recv failed! calling signoff....\n";
    $self->callback($SFLAP_SIGNOFF);
    return;
  }

  my ($id, $chan, $seq, $len, $data) = unpack("aCnn", $buffer);
  $self->debug("sflap recv ($self->{fd}) $foo chan = $chan seq = $seq len = $len\n");

  $foo = CORE::sysread($fd, $data, $len);
  $self->debug("      data = $data\n");

  $self->callback($chan, $data);

  return $buffer;
}

sub send {
  my ($self, $chan, $data, $length) = @_;
  my $buffer;
  my $format;

  if (!$length) {
    $length = length($data);
  }

  if ($chan == $SFLAP_DATA) {
    $format = "cCnna*C";
    $length ++;
  } else {
    $format = "cCnna*";
  }

  $self->{sequence} ++;
  $buffer = pack($format, 42, $chan, $self->{sequence},
                          $length, $data, 0);

  ($id, $ch, $seq, $len, $data, $nuller) = unpack($format, $buffer);

  $foo = CORE::syswrite($self->{fd}, $buffer, $length + 6);
  $self->debug("sflap send ($self->{fd}) $foo chan = $ch seq = $seq len = $len data = $data\n");
}

sub write {
  my ($self, $buffer, $len, $noflap) = @_;
  my $fd = $self->{fd};

  return CORE::syswrite($fd, $buffer, $len);
}

sub flush {
  my $self = shift;
}

1;
