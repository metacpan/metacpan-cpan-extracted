## -*- Mode: CPerl -*-
##
## File: DTA::CAB::Queue::Server.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: UNIX-socket based queue: server for command-line analyzer

package DTA::CAB::Queue::Server;
use DTA::CAB::Socket ':flags';
use DTA::CAB::Socket::UNIX;
use DTA::CAB::Queue::Client;
use DTA::CAB::Format;
use DTA::CAB::Format::Builtin;
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

## $qs = DTA::CAB::Queue::Server->new(%args)
##  + %$qs, %args:
##    (
##     ##-- NEW in DTA::CAB::Queue::Server
##     queue => \@queue,    ##-- actual queue data
##     status => $str,      ##-- queue status (defualt: 'active')
##     ntok => $ntok,       ##-- total number of tokens processed by clients
##     nchr => $nchr,       ##-- total number of characters processed by clients
##     blocks => \%blocks,  ##-- output tracker: %blocks = ($outfile => $po={cur=>$max_input_byte_written, pending=>\@pending}, ...)
##                          ##   + @pending is a list of pending blocks ($pb={off=>$ioffset, len=>$ilength, data=>\$data, ...}, ...)
##     logBlock => $level,  ##-- log-level for block merge operations (default=undef (none))
##     ##
##     ##-- INHERITED from DTA::CAB::Socket::UNIX
##     local  => $path,     ##-- path to local UNIX socket (server only; set to empty string to use a tempfile)
##     #peer   => $path,     ##-- path to peer socket (client only)
##     listen => $n,        ##-- queue size for listen (default=SOMAXCONN)
##     unlink => $bool,     ##-- if true, server socket will be unlink()ed on DESTROY() (default=true)
##     perms  => $perms,    ##-- file create permissions for server socket (default=0600)
##     pid => $pid,         ##-- pid of creating process (for auto-unlink)
##     ##
##     ##-- INHERITED from DTA::CAB::Socket
##     fh    => $sockfh,     ##-- an IO::Socket::UNIX object for the socket
##     timeout => $secs,     ##-- default timeout for select() (default=undef: none)
##     nonblocking => $bool, ##-- set O_NONBLOCK on open? (override default=true)
##     logSocket => $level,  ##-- log level for full socket trace (default=undef (none))
##     logRequest => $level, ##-- log level for client requests (server only; default=undef (none))
##    )
sub new {
  my $that = shift;
  return $that->SUPER::new(
			   local => '', ##-- use temp socket if unspecified

			   ##-- local data
			   queue=>[],
			   status => 'active',
			   ntok => 0,
			   nchr => 0,
			   blocks => {},

			   ##-- logging
			   logBlock   => undef,
			   logRequest => undef,
			   logSocket  => undef,

			   ##-- overrides
			   nonblocking => 1,

			   ##-- user args
			   @_,
			  );
}

##==============================================================================
## Open/Close

## $bool = $qs->opened()
## $qs = $qs->close()
## $qs = $qs->open(%args)
##  + all INHERITED from CAB::Socket::UNIX

##==============================================================================
## Socket Protocol
## + all INHERITED from CAB::Socket

##==============================================================================
## Queue Maintenance
##  + for use from main thread

## $n_items = $q->size()
sub size {
  return scalar(@{$_[0]{queue}});
}

## $n_items = $q->enq($item)
##  + enqueue an item; returns new number of items in queue
sub enq {
  push(@{$_[0]{queue}},$_[1]);
}

## $item_or_undef = $q->deq()
##  + de-queue a single item; undef at end-of-queue
sub deq {
  shift(@{$_[0]{queue}});
}

## $item = $q->peek()
##  + peek at the top of the queue; undef if queue is empty
sub peek {
  return $_[0]{queue}[0];
}

## $q = $q->clear()
##  + clear the queue
sub clear {
  @{$_[0]{queue}} = qw();
  return $_[0];
}

## ($ntok,$nchr) = $qs->addcounts($ntok,$nchr)
##  + get or add to total number of (tokens,character) processed
BEGIN {
  *counts = \&addcounts;
}
sub addcounts {
  $_[0]{ntok} += $_[1] if (defined($_[1]));
  $_[0]{nchr} += $_[2] if (defined($_[2]));
  return @{$_[0]}{qw(ntok nchr)};
}

## $qs = $qs->addblock(\%blk)
##   + append block \%blk to appropriate output file if possible, or save it for later
##   + %blk should have keys: (off=>$nbytes, len=>$nbytes, ofile=>$ofilename, fmt=>$class, data=>\$data, ...)
sub addblock {
  my ($qs,$blk) = @_;

  ##-- push block to block-tracker's ($bt) pending list
  my ($bt);
  $bt = $qs->{blocks}{$blk->{ofile}} = {cur=>0,pending=>[]} if (!defined($bt=$qs->{blocks}{$blk->{ofile}}));
  push(@{$bt->{pending}}, $blk);

  ##-- greedy append
  if ($blk->{id}[0] == $bt->{cur}) {
    my $fmt = DTA::CAB::Format->newFormat($blk->{ofmt} || $DTA::CAB::Format::CLASS_DEFAULT);
    @{$bt->{pending}} = sort {$a->{id}[0]<=>$b->{id}[0]} @{$bt->{pending}};
    while (@{$bt->{pending}} && $bt->{pending}[0]{id}[0]==$bt->{cur}) {
      $blk=shift(@{$bt->{pending}});

      $qs->vlog($qs->{logBlock}, "BLOCK_APPEND(ofile=$blk->{ofile}, id=$blk->{id}[0]/$blk->{id}[1], ioff=$blk->{ioff}, ilen=$blk->{ilen}, iend=".($blk->{ioff}+$blk->{ilen}).")");
      $fmt->blockAppend($blk);
      $bt->{cur}++;
    }
  } else {
    $qs->vlog($qs->{logBlock}, "BLOCK_DELAY(ofile=$blk->{ofile}, id=$blk->{id}[0]/$blk->{id}[1])");
  }

  return $qs;
}


##==============================================================================
## Server Methods

## $class = $CLASS_OR_OBJECT->clientClass()
##  + default client class, used by newClient()
sub clientClass {
  return 'DTA::CAB::Queue::ClientConn';
}

## $client = $CLASS_OR_OBJECT->newClient(%args)
##  + wrapper for clients, called by $s->accept()
##  + default just calls $CLASS_OR_OBJECT->clientClass->new(%args)
sub newClient {
  my $that = shift;
  return $that->clientClass->new(@_, logSocket=>$that->{logSocket});
}

## $cli_or_undef = $qs->accept()
## $cli_or_undef = $qs->accept($timeout_secs)
##  + accept incoming client connections with optional timeout
##  + INHERITED from DTA::CAB::Socket

## $rc = $qs->handleClient($cli)
## $rc = $qs->handleClient($cli, %callbacks)
##  + handle a single client request
##  + INHERITED from DTA::CAB::Socket

##--------------------------------------------------------------
## Server Methods: Request Handling
##
##  + request commands (case-insensitive) handled here:
##     ADDCOUNTS $NN : add to total number of (tokens,characters) processed; arg (string) $NN=pack('NN',$ntok,$chr); no response
##     ADDBLOCK $blk : block output; $blk is a HASH-ref passed to $qs->block($blk); no response
##     DEQ           : dequeue the first item in the queue; response: $cli->put($item)
##     DEQ_STR       : dequeue a string reference; response: $cli->put_str(\$item)
##     DEQ_REF       : dequeue a reference; response: $cli->put_ref($item)
##     ENQ $item     : enqueue an item; no response
##     ENQ_STR $str  : enqueue a string-reference; no response
##     ENQ_REF $ref  : enqueue a reference; no response
##     SIZE          : get current queue size; response=STRING $qs->size()
##     STATUS        : get queue status response: STRING $qs->{status}
##     CLEAR         : clear queue; no response
##     QUIT          : close client connection; no response
##     ...           : other messages are passed to $callback->(\$request,$cli) or produce an error
##  + returns: same as $callback->() if called, otherwise $qs


## $qs = $qs->handle_deq($cli,\$cmd)
## $qs = $qs->handle_deq_str($cli,\$cmd)
## $qs = $qs->handle_deq_ref($cli,\$cmd)
##  + implements "$item = DEQ", "\$str = DEQ_STR", "$ref = DEQ_REF"
BEGIN {
  *handle_deq_str = *handle_deq_ref = \&handle_deq;
}
sub handle_deq {
  my ($qs,$cli,$creq) = @_;
  my $cmd = lc($$creq);
  my $qu  = $qs->{queue};
  if ($cmd =~ /^deq(?:_ref|_str)?$/) {
    ##-- DEQ: dequeue an item
    if    (!@{$qs->{queue}})  { $cli->put_eoq(); }
    elsif ($cmd eq 'deq')     { $cli->put( $qu->[0] ); }
    elsif ($cmd eq 'deq_str') { $cli->put_str( ref($qu->[0]) ? $qu->[0] : \$qu->[0] ); }
    elsif ($cmd eq 'deq_ref') { $cli->put_ref( ref($qu->[0]) ? $qu->[0] : \$qu->[0] ); }
    shift(@$qu);
  }
  return $qs;
}

## $qs = $qs->handle_enq($cli,\$cmd)
##  + implements "ENQ $item"
sub handle_enq {
  my ($qs,$cli,$creq) = @_;
  my $buf = undef;
  my $ref = $cli->get(\$buf);
  push(@{$qs->{queue}}, ($ref eq \$buf ? $buf : $ref));
  return $qs;
}

## $qs = $qs->handle_enq_str($cli,\$cmd)
## $qs = $qs->handle_enq_ref($cli,\$cmd)
##  + implements "ENQ_STR \$str", "ENQ_REF $ref"
BEGIN {
  *handle_enq_str = *handle_enq_ref;
}
sub handle_enq_ref {
  my ($qs,$cli,$creq) = @_;
  my $ref = $cli->get();
  push(@{$qs->{queue}}, $ref);
  return $qs;
}

## $qs = $qs->handle_size($cli,$creq)
##  + implements "$size = SIZE"
sub handle_size {
  #my ($qs,$cli,$creq) = @_;
  #my $size = $_[0]->size;
  $_[1]->put_str($_[0]->size);
  return $_[0];
}

## $qs = $qs->handle_status($cli,$creq)
##  + implements "$status = STATUS"
sub handle_status {
  #my ($qs,$cli,$creq) = @_;
  $_[1]->put_str($_[0]{status});
  return $_[0];
}

## $qs = $qs->handle_clear($cli,$creq)
##  + implements "CLEAR"
sub handle_clear {
  @{$_[0]{queue}} = qw();
  return $_[0];
}

## $qs = $qs->handle_quit($cli,$creq)
##  + implements "QUIT"
BEGIN {
  *handle_bye = *handle_close = *handle_exit = \&handle_quit;
}
sub handle_quit {
  $_[1]->close();
  return $_[0];
}

## $qs = $qs->handle_addcounts($cli,\$cmd)
##  + implements "ADDCOUNTS pack('NN',$ntok,$nchr)"
sub handle_addcounts {
  my ($qs,$cli,$creq) = @_;
  my $buf = $cli->get();
  $qs->addcounts(unpack('NN',$$buf));
  return $qs;
}

## $qs = $qs->handle_addblock($cli,\$cmd)
##  + implements "ADDBLOCK \%blk"
sub handle_addblock {
  my ($qs,$cli,$creq) = @_;
  my $blk = $cli->get();
  $qs->addblock($blk);
  return $qs;
}

##==============================================================================
## Client Connections
package DTA::CAB::Queue::ClientConn;
use strict;
our @ISA = qw(DTA::CAB::Socket::UNIX);


1;

__END__
