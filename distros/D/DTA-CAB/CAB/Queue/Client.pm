## -*- Mode: CPerl -*-
##
## File: DTA::CAB::Queue::Client.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: UNIX-socket based queue: server

package DTA::CAB::Queue::Client;
use DTA::CAB::Socket ':flags';
use DTA::CAB::Socket::UNIX;
use DTA::CAB::Utils ':temp', ':files';
use Carp;
use strict;

##==============================================================================
## Globals
##==============================================================================
our @ISA = qw(DTA::CAB::Socket::UNIX);

##==============================================================================
## Constructors etc.
##==============================================================================

## $qc = DTA::CAB::Queue::Client->new(%args)
##  + %$qc, %args:
##    (
##     ##-- NEW in DTA::CAB::Queue::Client
##     peer => $path,       ##-- constructor override sets $qc->{peer} but suppresses auto-open() on new()
##     ##
##     ##-- INHERITED from DTA::CAB::Socket::UNIX
##     #local  => $path,     ##-- path to local UNIX socket (for server; set to empty string to use a tempfile)
##     peer   => $path,     ##-- path to peer socket (for client)
##     listen => $n,        ##-- queue size for listen (default=SOMAXCONN)
##     unlink => $bool,     ##-- if true, server socket will be unlink()ed on DESTROY() (default=true)
##     perms  => $perms,    ##-- file create permissions for server socket (default=0600)
##     ##
##     ##-- INHERITED from DTA::CAB::Socket
##     fh    => $sockfh,     ##-- an IO::Socket::UNIX object for the socket
##     timeout => $secs,     ##-- default timeout for select() (default=undef: none)
##     logSocket => $level,  ##-- log level for full socket I/O trace (default=undef (none))
##     logRequest => $level, ##-- log level for client requests (server only; default=undef (none))
##    )
sub new {
  my ($that,%args) = @_;
  my $peer = $args{peer};
  delete @args{qw(peer local)};
  my $qc = $that->SUPER::new(%args); ##-- no auto-open
  $qc->{peer} = $peer;
  return $qc;
}

##==============================================================================
## Open/Close
##  + all INHERITED from CAB::Socket::UNIX, CAB::Socket

##==============================================================================
## Socket Communications
## + all INHERITED from CAB::Socket

##==============================================================================
## Queue Server Protocol

## $qc = $qc->enq($item)
sub enq {
  $_[0]->reopen->put_str('enq')->put($_[1])->close;
}

## $qc = $qc->enq_str( $str)
## $qc = $qc->enq_str(\$str)
sub enq_str {
  $_[0]->reopen->put_str('enq_str')->put_str(ref($_[1]) ? $_[1] : \$_[1])->close;
}

## $qc = $qc->enq_ref($ref)
sub enq_ref {
  $_[0]->reopen->put_str('enq_ref')->put_ref(ref($_[1]) ? $_[1] : \$_[1])->close;
}

## $item = $qc->deq()
## $item = $qc->deq(\$buf)
sub deq {
  my ($flags,$len,$ref) = $_[0]->reopen->put_str('deq')->get(@_[1..$#_]);
  $_[0]->close;
  return ( ($flags & $sf_ref) ? $ref : $$ref );
}

## \$str = $qc->deq_str()
## \$str = $qc->deq_str( \$str )
sub deq_str {
  my $ref = $_[0]->reopen->put_str('deq_str')->get(@_[1..$#_]);
  $_[0]->close;
  return $ref;
}

## $ref = $qc->deq_ref()
## $ref = $qc->deq_ref( \$buf )
sub deq_ref {
  my $ref = $_[0]->reopen->put_str('deq_ref')->get(@_[1..$#_]);
  $_[0]->close;
  return $ref;
}


## $status = $qc->status()
##  + get server status
sub status {
  my $qc = shift;
  my $ref = $qc->reopen->put_str('status')->get;
  $qc->close();
  return $$ref;
}

## $size = $qc->size()
##  + get current length of server queue
sub size {
  my $qc = shift;
  my $ref = $qc->reopen->put_str('size')->get;
  $qc->close();
  return $$ref;
}

## undef = $qc->clear()
##  + clear the server queue
sub clear {
  $_[0]->reopen->put_str('clear')->close;
}

## undef = $qc->addcounts($ntok,$nchr)
sub addcounts {
  $_[0]->reopen->put_str('addcounts')->put_str(pack('NN',@_[1,2]))->close;
}

## undef = $qc->addblock(\%blk)
sub addblock {
  $_[0]->reopen->put_str('addblock')->put_ref($_[1])->close;
}

1;

__END__
