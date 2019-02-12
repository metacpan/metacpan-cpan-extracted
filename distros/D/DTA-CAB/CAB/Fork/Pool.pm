## -*- Mode: CPerl -*-
##
## File: DTA::CAB::Fork::Pool.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: generic thread pool for DTA::CAB

package DTA::CAB::Fork::Pool;
use DTA::CAB::Queue::Server;
use POSIX qw(:sys_wait_h);
use Carp;
use strict;

##==============================================================================
## Globals
##==============================================================================

our @ISA = qw(DTA::CAB::Queue::Server);

##==============================================================================
## Constructors etc.
##==============================================================================

## $fp = CLASS_OR_OBJ->new(%args)
##  + %$fp, %args:
##    {
##     ##-- high-level subprocess pool options
##     njobs  => $n_threads,    ##-- number of subprocesses to fork() off (default=0)
##     init   => \&init,        ##-- called as init($fp) in each subprocess after creation (default: $fp->can('init'))
##     work   => \&work,        ##-- called as work($fp,$item) in a subprocess to process a queue item (default: $fp->can('work'))
##     reap   => \&reap,        ##-- called as reap($fp,$pid,$?) after subprocess exit (default: $fp->can('reap'))
##     free   => \&free,        ##-- called as free($fp) in each subprocess before termination (default: $fp->can('free'))
##
##     logSpawn         => $level,   ##-- log-level for spawning subprocesses [default: 'info']
##     logReap          => $level,   ##-- log-level for own pids reaped with default reap() [default: 'info']
##     logReapOther     => $level,   ##-- log-level for other pids reaped with default reap() [default: none]
##     propagateErrors  => $bool,    ##-- if true (default), default 'reap' method will exit() the whole process
##     installReaper    => $bool,    ##-- if true (default), spawn() sets $SIG{CHLD}=$fp->reaper()
##
##     ##-- Low-level data
##     pids => \@pids,           ##-- PIDs of spawned subprocesses
##     ppid => $ppid,            ##-- parent pid (default=$$)
##     qc   => $qclient,         ##-- queue client (subprocesses only; see $fp->qclient(), below)
##
##     ##-- INHERITED from DTA::CAB::Queue::Server
##     queue => \@queue,    ##-- actual queue data
##     status => $str,      ##-- queue status (default: 'active')
##     ntok => $ntok,       ##-- total number of tokens processed by clients
##     nchr => $nchr,       ##-- total number of characters processed by clients
##     blocks => \%blocks,  ##-- output tracker: %blocks = ($outfile => $po={cur=>$max_input_byte_written, pending=>\@pending}, ...)
##                          ##   + @pending is a list of pending blocks ($pb={off=>$ioffset, len=>$ilength, data=>\$data, ...}, ...)
##     logBlock => $level,  ##-- log-level for block merge operations (default=undef (none))
##
##     ##-- INHERITED from DTA::CAB::Socket::UNIX
##     local  => $path,     ##-- path to local UNIX socket (server only; set to empty string to use a tempfile): OVERRIDE default=''
##     #peer   => $path,     ##-- path to peer socket (client only)
##     listen => $n,        ##-- queue size for listen (default=SOMAXCONN)
##     unlink => $bool,     ##-- if true, server socket will be unlink()ed on DESTROY() (default=true)
##     perms  => $perms,    ##-- file create permissions for server socket (default=0600)
##     pid => $pid,         ##-- pid of creating process (for auto-unlink)
##
##     ##-- INHERITED from DTA::CAB::Socket
##     fh    => $sockfh,     ##-- an IO::Socket::UNIX object for the socket
##     timeout => $secs,     ##-- default timeout for select() (default=undef: none); OVERRIDE default=1
##     nonblocking => $bool, ##-- set O_NONBLOCK on open? (override default=true);    OVERRIDE default=1
##     logSocket => $level,  ##-- log level for full socket trace (default=undef (none))
##     logRequest => $level, ##-- log level for client requests (server only; default=undef (none))
##    }
sub new {
  my $that = shift;
  my $fp = $that->SUPER::new
    (
     njobs => 0,
     init  => $that->can('init'),
     work  => $that->can('work'),
     reap  => $that->can('reap'),
     free  => $that->can('free'),
     propagateErrors => 1,
     installReaper => 1,
     pids => [],
     ppid => $$,

     ##-- logging
     logSpawn => 'info',
     logReap  => 'info',
     logReapOther  => 'debug',
     #logSocket => 'debug',
     #logRequest => 'trace',
     #logBlock => 'debug',

     ##-- overrides
     local => '',
     timeout => 1,
     nonblocking => 1,

     @_,
    );
  return $fp;
}

##==============================================================================
## Methods: Pool Maintainence

## $fp = $fp->spawn()
##  + ensures that at least $fp->{njobs} PIDs are defined in $fp->{pids}
##  + you must completely populate the queue BEFORE calling this method!
sub spawn {
  my $fp = shift;
  $fp->{pids} = [] if (!$fp->{pids});
  $SIG{CHLD} = $fp->reaper() if ($fp->{installReaper});
  while (@{$fp->{pids}} < $fp->{njobs}) {
    my $pid = fork();
    if ($pid) {
      ##-- parent
      $fp->vlog($fp->{logSpawn},"spawned subprocess $pid");
      push(@{$fp->{pids}},$pid);
    } else {
      ##-- child
      $fp->logconfess("couldn't fork()") if (!defined($pid));
      $fp->{fh}->close() if ($fp->{fh}); ##-- close server queue socket in child
      exit $fp->childMain();
    }
  }
  return $fp;
}

## $fp = $fp->is_child()
##  + returns true if current process is a child; wraps ($fp->{ppid} && $$!=$fp->{ppid})
sub is_child {
  return $_[0]{ppid} && $$!=$_[0]{ppid};
}

## $fp = $fp->abort()
## $fp = $fp->abort($SIGNAL)
##  + kills subprocesses
sub abort {
  my ($fp,$sig) = @_;
  $sig = 'TERM' if (!defined($sig));
  my ($pid);
  while (defined($pid=shift(@{$fp->{pids}}))) {
    kill($sig,$pid);
  }
  return $fp;
}

## $fp = $fp->reset()
##  + aborts all running subprocesses and empties the queue
sub reset {
  my $fp = shift;
  $fp->abort();
  $fp->clear();
  return $fp;
}

## @pids = $fp->pids
##  + list of all child processes
sub pids {
  return @{$_[0]{pids}};
}

## $fp = $fp->waitall()
##  + waits on all child pids
sub waitall {
  my $fp = shift;
  my ($child);
  while (($child = waitpid(-1,0))>0) {
    $fp->{reap}->($fp,$child,$?) if ($fp->{reap});
    @{$fp->{pids}} = grep {$_ != $child} @{$fp->{pids}};
  }
  return $fp;
}

## \&reaper = $fp->reaper()
##  + zombie-harvesting code; installed to local %SIG if $fp->{installReaper} is true (default)
sub reaper {
  my $fp = shift;
  return sub {
    my ($child);
    while (($child = waitpid(-1,WNOHANG)) > 0) {
      if ($fp->{reap}) {
	$fp->{reap}->($fp,$child,$?) ;
      } else {
	$fp->vlog($fp->{logReap},"reaper got subprocess pid=$child, status=$?");
      }
      @{$fp->{pids}} = grep {$_ != $child} @{$fp->{pids}};
    }
    #$SIG{CHLD}=$fp->reaper() if ($fp->{installReaper}); ##-- re-install reaper for SysV
  };
}

##==============================================================================
## Methods: Queue Maintainence
##  + see DTA::CAB::Queue::Server

## $client = $fp->qclient()
##  + returns a (new) pseudo-client for the $fp queue
##  + just returns $fp in main process
##  + uses cached $fp->{qc} if available, otherwise caches $fp->{qc} to a new DTA::CAB::Queue::Client
sub qclient {
  return $_[0] if ($$ == $_[0]{ppid});      ##-- main process: use $fp methods directly
  return $_[0]{qc} if (defined($_[0]{qc})); ##-- child with cached client object
  return $_[0]{qc} = DTA::CAB::Queue::Client->new(peer=>$_[0]{local}, logSocket=>$_[0]{logSocket});
}

## undef = $fp->qenq($item)
##  + enqueue a single item; server or client
sub qenq {
  $_[0]->qclient->enq(@_[1..$#_]);
}

## $item = $fp->qdeq()
##  + dequeue a single item; server or client
sub qdeq {
  $_[0]->qclient->deq(@_[1..$#_]);
}

## $size = $fp->qsize()
sub qsize {
  $_[0]->qclient->size;
}

## undef = $fp->qaddcounts($ntok,$nchr)
sub qaddcounts {
  $_[0]->qclient->addcounts(@_[1..$#_]);
}

## undef = $fp->qaddblock(\%blk)
sub qaddblock {
  $_[0]->qclient->addblock(@_[1..$#_]);
}

##==============================================================================
## Methods: Main Server Loop

## undef = $fp->serverMain()
##  + main server loop
##  + spawns sub-process(es) if $fp->{njobs}>=1
##  + serves the queue until all subprocesses have existed
sub serverMain {
  my $fp = shift;

  ##-- do we need to fork at all?
  if ($fp->{njobs} < 1) {
    $fp->info("requested njobs=$fp->{njobs}; not forking");
    return $fp->processMain();
  }

  ##-- sanity check(s)
  $fp->open() if (!defined($fp->{fh}));                   ##-- ensure server socket is open
  $fp->{njobs} = $fp->size if ($fp->{njobs} > $fp->size); ##-- don't fork() more than we need to
  $fp->spawn();
  $fp->info("spawned $fp->{njobs} worker subprocess(es)");

  ##-- serve the queue
  my ($cli);
  while (@{$fp->{pids}}) {
    #$fp->trace("polling for client(s)..."); ##-- DEBUG
    next if (!defined($cli=$fp->accept));
    $fp->handleClient($cli);
    $cli->close();
  }

  return;
}

##==============================================================================
## Methods: Job Processing

## undef = PACKAGE::childMain($fp)
##   + queue worker sub which wraps init() and free() calls around $fp->processMain()
sub childMain {
  my $fp = shift;
  $fp->{init}->($fp) if ($fp->{init});
  $fp->processMain();
  $fp->{free}->($fp) if ($fp->{free});
  exit 0;
}

## undef = PACKAGE::processMain($fp)
##   + main queue processing loop (can be called either from main or child thread)
sub processMain {
  my $fp = shift;
  my ($item);
  while (defined($item=$fp->qdeq)) {
    $fp->{work}->($fp,$item) if ($fp->{work});
  }
}

##==============================================================================
## Methods: Default Child Callbacks

## undef = init($fp)
##  + default thread initializer (no-op)
sub init { ; }

## undef = work($fp,$item)
##  + default thread queue-processor (no-op)
sub work { ; }

## undef = free($fp)
##  + default thread cleanup function (no-op)
sub free { ; }

## undef = reap($fp,$pid,$?)
##  + called from main thread on subprocess exit
sub reap {
  my ($fp,$pid,$status) = @_;
  if (grep {$_==$pid} @{$fp->{pids}//[]}) {
    $fp->vlog($fp->{logReap},"reaped subprocess $pid with exit status $status");
    if ($fp->{propagateErrors} && $status != 0) {
      $fp->abort();
      $fp->logdie("subprocess $pid exited with abnormal status $status");
    }
  } else {
    $fp->vlog($fp->{logReapOther},"reaped external subprocess $pid with exit status $status");
  }
}



1; ##-- be happy

__END__
