## -*- Mode: CPerl -*-
##
## File: DTA::CAB::Socket.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: UNIX-socket based queue: common utilities

package DTA::CAB::Socket;
use DTA::CAB::Logger;
use DTA::CAB::Utils ':files';
use IO::Handle;
use IO::File;
use IO::Socket;
use Errno qw(EINTR);
use Fcntl ':DEFAULT';
use Storable;
use Carp;
use Exporter;
use strict;

##==============================================================================
## Globals
##==============================================================================
our @ISA = qw(Exporter DTA::CAB::Logger);

our @EXPORT = qw();
our %EXPORT_TAGS =
  (
   'flags' => [qw($sf_eoq $sf_undef $sf_u8 $sf_ref)],
  );
our @EXPORT_OK = map {@$_} values %EXPORT_TAGS;
$EXPORT_TAGS{all} = [@EXPORT_OK];

##==============================================================================
## Constructors etc.
##==============================================================================

## $s = DTA::CAB::Socket->new(%args)
##  + %$s, %args:
##    (
##     fh       => $sockfh,  ##-- an IO::Socket object for the socket
##     timeout  => $secs,    ##-- default timeout for select() (default=undef: none)
##     nonblocking => $bool, ##-- set O_NONBLOCK on open() if true (default=false)
##     logSocket => $level,  ##-- log level for full socket trace (default=undef (none))
##     logRequest => $level, ##-- log level for client requests (default=undef (none))
##    )
sub new {
  my ($that,%args) = @_;
  my $s = bless({
		 #path =>undef,
		 timeout=>undef,
		 nonblocking => 0,
		 logSocket => undef,
		 logRequest => undef,
		 (ref($that) ? (%$that) : qw()),
		 fh   =>undef,
		 %args,
		}, ref($that)||$that);
  return $s;
}

## undef = $s->DESTROY
##  + destructor calls close()
sub DESTROY {
  $_[0]->close();
}

##==============================================================================
## Debug

## undef = $s->vtrace(@msg)
##  + logs @msg at $s->{logSocket}
sub vtrace {
  $_[0]->vlog($_[0]{logSocket}, join(' ', map {defined($_) ? $_ : '--undef--'} @_[1..$#_])) if (defined($_[0]{logSocket}));
}

##==============================================================================
## Open/Close

## $bool = $s->opened()
sub opened {
  return defined($_[0]{fh}) && $_[0]{fh}->opened();
}

## $s = $s->close()
##  + closes the socket and deletes $s->{fh}
sub close {
  my $s = shift;
  $s->{fh}->close() if ($s->opened);
  delete($s->{fh});
  return $s;
}

## $s_or_undef = $s->open(%args)
##   + default implementation just dies
sub open {
  $_[0]->vtrace("open ", @_[1..$#_]);
  $_[0]->logconfess("abstract open() method not implemented");
}

## $s = $s->reopen()
##  + wrapper just calls $s->open()
sub reopen {
  $_[0]->open(@_[1..$#_]);
}

## $s = $s->connect()
##  + wrapper for $s->open()
sub connect {
  return $_[0]->open(@_[1..$#_]);
}


##==============================================================================
## Select

## $flags = $s->flags()
##  + get fcntl flags
sub flags {
  return fcntl($_[0]{fh}, F_GETFL, 0)
}

## $bool = $s->nonblocking()
## $bool = $s->nonblocking($bool)
##  + get current value of O_NONBLOCK flag
sub nonblocking {
  if (@_ > 1) {
    fcntl($_[0]{fh}, F_SETFL, ($_[1] ? ($_[0]->flags | O_NONBLOCK) : ($_[0]->flags & ~O_NONBLOCK)))
      or $_[0]->logconfess("canread(): could not set flags on socket fd ", fileno($_[0]{fh}), ": $!");
  }
  return $_[0]->flags & O_NONBLOCK;
}

## $bool = $s->canread()
## $bool = $s->canread($timeout_secs)
##  + returns true iff there is readable data on the socket
##  + $timeout_secs defaults to $s->{timeout} (0 for none)
##  + temporarily sets O_NONBLOCK for the socket
##  + should return true for a server socket if at least one client is waiting to connect
sub canread {
  #$_[0]->vtrace('canread');
  my $s = shift;
  my $timeout = @_ ? shift : $s->{timeout};
  my $flags0 = $s->flags;
  if (!($flags0 & O_NONBLOCK)) {
    fcntl($s->{fh}, F_SETFL, $flags0 | O_NONBLOCK)
      or $s->logconfess("canread(): could not set O_NOBLOCK on socket: $!");
  }
  my $rbits = fhbits($s->{fh});
  my $nfound = select($rbits, undef, undef, $timeout);
  if (!($flags0 & O_NONBLOCK)) {
    fcntl($s->{fh}, F_SETFL, $flags0)
      or $s->logconfess("canread(): could not reset socket flags: $!");
  }
  return $nfound;
}

## $bool = $s->canwrite()
## $bool = $s->canwrite($timeout_secs)
##  + returns true iff data can be written to the socket
##  + $timeout_secs defaults to $s->{timeout} (0 for none)
##  + temporarily sets O_NONBLOCK for the socket
sub canwrite {
  #$_[0]->vtrace('canwrite');
  my $s = shift;
  my $timeout = @_ ? shift : $s->{timeout};
  my $flags0 = $s->flags;
  if (!($flags0 & O_NONBLOCK)) {
    fcntl($s->{fh}, F_SETFL, $flags0 | O_NONBLOCK)
      or $s->logconfess("canwrite(): could not set O_NOBLOCK on socket: $!");
  }
  my $wbits = fhbits($s->{fh});
  my $nfound = select(undef, $wbits, undef, $timeout);
  if (!($flags0 & O_NONBLOCK)) {
    fcntl($s->{fh}, F_SETFL, $flags0)
      or $s->logconfess("canwrite(): could not reset socket flags: $!");
  }
  return $nfound;
}

## $s = $s->waitr()
##  + waits indefinitely for input; wrapper for $s->canread(undef)
sub waitr {
  return $_[0]->canread(undef) ? $_[0] : undef;
}

## $bool = $s->waitw()
##  + wrapper for $s->canwrite(undef)
sub waitw {
  return $_[0]->canwrite(undef) ? $_[0] : undef;
}

##==============================================================================
## Server Methods

## $class = $CLASS_OR_OBJECT->clientClass()
##  + default client class, used by newClient()
sub clientClass {
  return ref($_[0]) || $_[0];
}

## $client = $CLASS_OR_OBJECT->newClient(%args)
##  + wrapper for clients, called by $s->accept()
##  + default just calls $CLASS_OR_OBJECT->clientClass->new(%args)
sub newClient {
  my $that = shift;
  return $that->clientClass->new(@_);
}

## $cli_or_undef = $s->accept()
## $cli_or_undef = $s->accept($timeout_secs)
##  + accept incoming client connections with optional timeout
##  + if a client connection is available, it will be returned with $s->newClient(fh=>$fh)
##  + otherwise, if no connection is available, undef will be returned
sub accept {
  my $s = shift;
  my $timeout = @_ ? shift : $s->{timeout};
  if (!defined($timeout) || $s->canread($timeout)) {
    my $cfh = $s->{fh}->accept();
    return undef if (!defined($cfh));
    return $s->newClient(fh=>$cfh);
  }
  return undef;
}

## $rc = $qs->handleClient($cli)
## $rc = $qs->handleClient($cli, %callbacks)
##  + handle a single client request
##  + each client request is a STRING message (command)
##    - request arguments (if required) are sent as separate messages following the command request
##    - server response (if any) depends on command sent
##  + this method parses client request command $cmd and dispatches to
##    - the function $callbacks{lc($cmd)}->($qs,$cli,\$cmd), if defined
##    - the method $qs->can("handle_".lc($cmd))->($qs,$cli,\$cmd), if available
##    - the function $callbacks{DEFAULT}->($qs,$cli,\$cmd), if defined
##    - the method $qs->can("handle_DEFAULT")->($qs,$cli,\$cmd)
##  + returns whatever the handler subroutine does
sub handleClient {
  my ($qs,$cli,%callbacks) = @_;
  my $creq = $cli->get();
  $qs->vlog($qs->{logRequest}, "client request: $$creq");
  if (!ref($creq) || ref($creq) ne 'SCALAR' || ref($$creq)) {
    $qs->logconfess("could not parse client request");
  }
  my $cmd = lc($$creq);
  my ($sub);
  if (defined($sub=$callbacks{$cmd})) {
    return $sub->($qs,$cli,$creq);
  }
  elsif (defined($sub=$qs->can("handle_${cmd}"))) {
    return $sub->($qs,$cli,$creq);
  }
  elsif (defined($sub=$callbacks{DEFAULT})) {
    return $sub->($qs,$cli,$creq);
  }
  elsif (defined($sub=$qs->can("handle_DEFAULT"))) {
    return $sub->($qs,$cli,$creq);
  }
  ##-- should never get here
  $qs->logconfess("could not dispatch client request $$creq");
  return undef;
}

##--------------------------------------------------------------
## Server Methods: Request Handling

## undef = $qs->handle_DEFAULT($cli,\$cmd)
##  + default implementation just logcluck()s and returns undef
sub handle_DEFAULT {
  $_[0]->logcluck("cannot handle client client request ${$_[2]}");
  return undef;
}

##==============================================================================
## Protocol
##  + all socket messages are of the form pack('NN/a*', $flags, $message_data)
##  + $flags is a bitmask of DTA::CAB::Socket flags ($sf_* constants)
##  + length element (second 'N' of pack format) is always 0 for serialized references
##  + $message_data is one of the following:
##    - if    ($flags & $sf_ref)   -> a reference written with nstore_fd(); will be decoded
##    - elsif ($flags & $sf_u8)    -> a UTF-8 encoded string; will be decoded
##    - elsif ($flags & $sf_undef) -> a literal undef value
##    - elsif ($flags & $sf_eoq)   -> undef as end-of-queue marker

##--------------------------------------------------------------
## Protocol: Constants
our $sf_eoq   = 0x1;
our $sf_undef = 0x2;
our $sf_u8    = 0x4;
our $sf_ref   = 0x8;

##--------------------------------------------------------------
## Protocol: Write

## $s = $s->put_header($flags,$len)
##  + write a message header to the socket
sub put_header {
  $_[0]->vtrace("put_header", @_[1..$#_]);
  syswrite($_[0]{fh}, pack('NN', @_[1,2]), 8)==8
    or $_[0]->logconfess("put_header(): could not write message header to socket: $!");
  return $_[0];
}

## $s = $s->put_data(\$data, $len)
## $s = $s->put_data( $data, $len)
##  + write some raw data bytes to the socket (header should already have been sent)
sub put_data {
  $_[0]->vtrace("put_data", @_[1..$#_]);
  return if (!defined($_[0]));
  use bytes;
  my $ref = ref($_[1]) ? $_[1] : \$_[1];
  my $len = defined($_[2]) ? $_[2] : length($$ref);
  if ($len > 0) {
    syswrite($_[0]{fh}, $$ref, $len)==$len
      or $_[0]->logconfess("put_data(): could not write message data to socket: $!");
  }
  return $_[0];
}

## $s = $s->put_msg($flags,$len, $data)
## $s = $s->put_msg($flags,$len,\$data)
##  + write a whole message to the socket
sub put_msg {
  $_[0]->put_header(@_[1,2]) && $_[0]->put_data(@_[3,2]);
}


## $s = $s->put_ref($ref)
##  + write a reference to the socket with Storable::nstore() (length written as 0)
sub put_ref {
  $_[0]->vtrace("put_ref", @_[1..$#_]);
  $_[0]->put_header( $sf_ref | (defined($_[1]) ? 0 : $sf_undef), 0 );
  return $_[0] if (!defined($_[1]));
  Storable::nstore_fd($_[1], $_[0]{fh})
      or $_[0]->logconfess("put_ref(): nstore_fd() failed for $_[1]: $!");
  return $_[0];
}

## $s = $s->put_str(\$str)
## $s = $s->put_str( $str)
##  + write a raw string message to the socket
##  + auto-magically sets $sf_undef and $sf_u8 flags
sub put_str {
  $_[0]->vtrace("put_str", @_[1..$#_]);
  use bytes;
  my $ref   = ref($_[1]) ? $_[1] : \$_[1];
  my $flags = (defined($$ref) ? (utf8::is_utf8($$ref) ? $sf_u8 : 0) : $sf_undef);
  my $len   = (defined($$ref) ? length($$ref) : 0);
  $_[0]->put_msg($flags,$len,$ref);
}

## $s = $s->put_undef()
sub put_undef {
  $_[0]->vtrace("put_undef", @_[1..$#_]);
  $_[0]->put_msg( $sf_undef, 0, undef );
}

## $s = $s->put_eoq()
sub put_eoq {
  $_[0]->vtrace("put_eoq", @_[1..$#_]);
  $_[0]->put_msg( $sf_eoq|$sf_undef, 0, undef );
}


## $s = $s->put( $thingy )
##  + write an arbitrary thingy to the socket
##  + if $thingy is a SCALAR or a reference to a bare SCALAR, calls $s->put_str($thingy)
##  + otherwise calls $s->put_ref($thingy)
sub put {
  $_[0]->vtrace("put", @_[1..$#_]);
  return $_[0]->put_undef() if (!defined($_[1]));
  return $_[0]->put_str(\$_[1]) if (!ref($_[1]));
  return $_[0]->put_str( $_[1]) if ( ref($_[1]) eq 'SCALAR' && !ref(${$_[1]}) );
  return $_[0]->put_ref( $_[1]);
}

##--------------------------------------------------------------
## Protocol: Read

## $nbytes_read = $s->safe_sysread(\$bufr, $nbytes)
##  + safe wrapper for CORE::sysread which avoids EINTR ("Interrupted system call") errors
sub safe_sysread {
  my ($s,$bufr,$nbytes) = @_;
  my ($rc);
  my $nread = 0;
  while ($nbytes > 0) {
    if ( !($rc = CORE::sysread($s->{fh},$$bufr,$nbytes,$nread)) ) {
      next if ($! == EINTR);
      return undef; ##-- other error
    }
    $nbytes -= $rc;
    $nread  += $rc;
  }
  return $nread;
}

## ($flags,$len)  = $s->get_header(); ##-- list context
## $header_packed = $s->get_header(); ##-- scalar context
##  + gets header from socket
sub get_header {
  $_[0]->vtrace("get_header", @_[1..$#_]);
  my ($hdr);
  #CORE::sysread($_[0]{fh}, $hdr, 8)==8
  $_[0]->safe_sysread(\$hdr,8)==8
    or $_[0]->logconfess("get_header(): could not read message header from socket: $!");
  return wantarray ? unpack('NN',$hdr) : $hdr;
}

## \$buf = $s->get_data($len)
## \$buf = $s->get_data($len,\$buf)
##   + reads $len bytes of data from the socket
sub get_data {
  $_[0]->vtrace("get_data", @_[1..$#_]);
  my ($s,$len,$bufr) = @_;
  $bufr  = \(my $buf) if (!defined($bufr));
  $$bufr = undef;
  if ($len > 0) {
    #CORE::sysread($s->{fh}, $$bufr, $len)==$len
    $s->safe_sysread($bufr, $len)==$len
      or $s->logconfess("get_data(): could not read message of length=$len bytes from socket: $!");
  }
  return $bufr;
}

## $ref = $s->get_ref_data()
##  + reads reference data from the socket with Storable::fd_retrieve()
##  + header should already have been read
sub get_ref_data {
  $_[0]->vtrace("get_ref_data", @_[1..$#_]);
  return
    Storable::fd_retrieve($_[0]{fh})
      || $_[0]->logconfess("get_ref_data(): fd_retrieve() failed");
}

## \$str_or_undef = $s->get_str_data($flags, $len)
## \$str_or_undef = $s->get_str_data($flags, $len, \$str)
##  + reads string bytes from the socket (header should already have been read)
##  + returned value is auto-magically decoded
sub get_str_data {
  $_[0]->vtrace("get_str_data", @_[1..$#_]);
  my $s   = shift;
  my $bufr = $s->get_data(@_[1,2]);
  $$bufr = '' if (!defined($$bufr));           ##-- get_data() returns empty string as undef
  utf8::decode($$bufr) if ($_[0] & $sf_u8);
  return $bufr;
}


## $ref_or_undef      = $s->get( );        ##-- SCALAR context, local buffer
## ($flags,$len,$ref) = $s->get( );        ##-- LIST context, local buffer
## $ref_or_undef      = $s->get( \$buf );  ##-- SCALAR context, user buffer
## ($flags,$len,$ref) = $s->get( \$buf );  ##-- LIST context, user buffer
##  + gets next message from the buffer
##  + if passed, \$buf is used as a data buffer,
##    - it will hold the string data actually read from the socket
##    - in the case of string messages, \$buf is also the value returned
##    - in the case of ref messages, \$buf is the serialized (nfreeze()) reference
##    - for undef or end-of-queue messages, $$buf will be set to undef
sub get {
  $_[0]->vtrace("get", @_[1..$#_]);
  my ($s,$bufr)   = @_;
  my ($flags,$len) = $s->get_header();
  if ($flags & ($sf_eoq | $sf_undef)) {
    $bufr = \undef;
  } elsif ($flags & $sf_ref) {
    $bufr = $s->get_ref_data();
  } else {
    $bufr = $s->get_str_data($flags,$len,$bufr);
  }
  return wantarray ? ($flags,$len,$bufr) : $bufr;
}


1; ##-- be happy

__END__
