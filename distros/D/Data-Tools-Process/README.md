# NAME

    Data::Tools::Process provides set of functions for process control,
    forking, daemonizing and pid files handling.

# SYNOPSIS

    use Data::Tools::Process qw( :all );  # import all functions
    use Data::Tools::Process;             # the same as :all :)
    use Data::Tools::Process qw( :none ); # do not import anything

    # --------------------------------------------------------------------------

    # fork and exec a command, returns the child pid to the parent
    my $pid = fork_exec_cmd( "/usr/bin/somecmd --with args" );
    waitpid( $pid, 0 );

    # --------------------------------------------------------------------------

    # detach from the controlling terminal and become a daemon
    daemonize();
    daemonize( CHDIR => '/var/lib/myapp', UMASK => 0022 );
    daemonize( STDOUT => '/var/log/myapp.log', STDERR => '/var/log/myapp.err' );
    daemonize( CLOSE_ALL_FDS => 1 );

    # the same, but stay in the current directory
    daemonize_here( STDOUT => 'myapp.log', STDERR => 'myapp.log' );

    # --------------------------------------------------------------------------

    # create a pid file, holding the pid of the current process
    my $res = pidfile_create( '/var/run/myapp.pid' );
    die "already running with pid [$res]" if $res;

    # ...and take over the pid file if the process in it is gone
    my $res = pidfile_create( '/var/run/myapp.pid', STALE_CHECK => 1 );

    # signal the process named in a pid file and remove the file
    pidfile_kill_and_remove( '/var/run/myapp.pid' );          # sends TERM
    pidfile_kill_and_remove( '/var/run/myapp.pid', 15, '5s', 9 );

    # just remove the pid file
    pidfile_remove( '/var/run/myapp.pid' );

    # --------------------------------------------------------------------------

    # check if the current directory was removed under the process
    die "current directory is gone" if cwd_gone();

    # the same for any path
    print "log dir is gone\n" if path_gone( '/var/log/myapp' );

    # --------------------------------------------------------------------------

# FUNCTIONS

## fork\_exec\_cmd( $command )

Forks and exec()s $command in the child process.

Returns:

    * the child process pid in the parent process
    * undef if fork() failed

The child never returns. $command is passed to exec() as a single string,
so it is subject to the usual shell handling of exec().

## daemonize( %options )

Detaches the current process from the controlling terminal and turns it into
a daemon: forks, calls POSIX::setsid(), forks again (SVR4 second fork policy),
changes the current directory, closes STDIN, STDOUT and STDERR (and all other
open file descriptors if CLOSE\_ALL\_FDS is set) and reopens them as file
descriptors 0, 1 and 2. STDIN is always /dev/null, STDOUT and STDERR are
/dev/null unless files are given for them.

Options are:

    CHDIR         => $path   # directory to change to, default is '/'
    UMASK         => $umask  # umask to set, default is 0077
    STDOUT        => $file   # file for STDOUT, default is /dev/null
    STDERR        => $file   # file for STDERR, default is /dev/null
    CLOSE_ALL_FDS => 1       # close all open file descriptors, default is
                             # to close only 0, 1 and 2, see below

STDOUT and STDERR files are opened for append and created if missing, with
permissions limited by UMASK (0600 with the default). Relative file names
are resolved after the change to CHDIR, so with the default CHDIR '/'
use full paths (or daemonize\_here()). STDOUT and STDERR may name the same
file. STDOUT is buffered, set autoflush on it if log lines must show up
immediately.

CLOSE\_ALL\_FDS => 1 closes file descriptors up to the system limit
(sysconf \_SC\_OPEN\_MAX), but not above 1024, since under a high open files
limit (ulimit -n) closing them one by one can take a long time. A value
from 2 to 1024 (e.g. CLOSE\_ALL\_FDS => 2) closes up to the system limit
uncapped. A value above 1024 is used as the cap instead of 1024, e.g.
CLOSE\_ALL\_FDS => 65536 closes up to the system limit, but not above 65536.

Returns 1 in the resulting daemon process. The original process and the
intermediate one leave with POSIX::\_exit(0) and never return, so END blocks
and object destructors are not run in them (they run only in the daemon,
when it exits). Dies on any of the steps failing.

    NOTE: the original process exits (with status 0) before STDOUT/STDERR
          files are opened, and STDERR is already closed when they are, so a
          bad STDOUT or STDERR file name (missing directory, no permissions)
          makes the daemon die() silently: nothing is printed anywhere and
          the caller sees success. check that the files can be opened before
          calling daemonize(), for example open them for append and close
          them, using the same names as they will be resolved after CHDIR.

    NOTE: without CLOSE_ALL_FDS all file descriptors other than 0, 1 and 2 are
          inherited by the daemon, close the ones it must not hold (pipes,
          locks, sockets). with CLOSE_ALL_FDS all open file descriptors are
          closed, including any files, sockets or database handles opened
          before the call, and perl handles to them must not be used anymore.

## daemonize\_here( %options )

The same as daemonize() but the CHDIR default is the current working
directory instead of '/', so the daemon stays where it was started and
relative STDOUT/STDERR file names are relative to it. All daemonize()
options are accepted, an explicit CHDIR overrides the default.

## pidfile\_create( $pid\_file\_name, %options )

Creates $pid\_file\_name and writes the pid of the current process in it. The
file is created with O\_EXCL, so two processes racing for the same pid file
cannot both succeed. Missing directories on the way are created.

Options are:

    STALE_CHECK => 1  # take over the pid file if its process is not running

Returns:

    * undef on success, the pid file now holds our pid
    * a positive pid if the pid file exists and holds a running process
    * -1 if the pid file cannot be created

A pid file which does not hold a valid (positive) pid is always considered
stale and is replaced, regardless of STALE\_CHECK.

## pidfile\_kill\_and\_remove( $pid\_file\_name, @signal\_list )

Sends the given signals to the pid found in $pid\_file\_name and then removes
the file. @signal\_list defaults to a single TERM (15).

A list item ending with 's' is not a signal but a sleep time in seconds. All
items are processed in the given order, so:

    pidfile_kill_and_remove( $fname, 15, '5s', 15, '2s', 9 );

sends TERM, waits 5 seconds, sends TERM again, waits 2 seconds, sends KILL.

Returns:

    * undef if $pid_file_name does not exist
    * 1 if the signals have been sent and the pid file removed

## pidfile\_remove( $pid\_file\_name )

Removes $pid\_file\_name. Returns undef.

## path\_gone( $path )

Checks if $path is gone. Returns true if $path cannot be stat()-ed (it does
not exist, or the stat fails with ESTALE or similar on a network file
system), or if its link count is 0 (it was unlinked). Returns false if
$path is still there.

Note that a link count of 0 can only be seen through something still
holding the removed entry, like the current directory ('.') of a process
whose directory was removed. A removed path given by name just fails stat().

## cwd\_gone()

The same as path\_gone( '.' ): returns true if the current working directory
of the process was removed (or is no longer accessible on a network file
system), false otherwise. Useful for long running processes and daemons
started with daemonize\_here(), whose directory may be removed under them.

# REQUIRED MODULES

Data::Tools::Process uses:

    * POSIX
    * Data::Tools

# GITHUB REPOSITORY

    git@github.com:cade-vs/perl-data-tools-process.git

    git clone git://github.com/cade-vs/perl-data-tools-process.git

# AUTHOR

    Vladi Belperchinov-Shabanski "Cade"
          <cade@noxrun.com> <cade@bis.bg> <cade@cpan.org>
    http://cade.noxrun.com/
# NAME

Data::Tools::Process::Forks - Fork process creation and control

# SYNOPSIS

    use Data::Tools::Process::Forks;

    # set up signal handlers for graceful shutdown (optional)
    forks_setup_signals();

    # configure maximum concurrent forks (default is 8)
    forks_set_max( 18 );

    # case A: start simple worker processes
    for my $task ( @tasks )
      {
      # this is the parent process, fork and continue
      forks_start_one( 'THINKER' ) and next; 
      
      # here is the forked child process, do some work and exit:
      # ...
      exit 111;
      # exit here is mandatory and omitting it would be a problem, 
      # since it will start forking more processes from the child one!
      # however it is the most simple use case.
      }

    # wait for all children to finish
    forks_wait_all();



    # case B: start worker processes with sub reference or closure
    for my $task ( @tasks )
      {
      forks_start_one( 'GOPHER', \&fetch_things ); 
      forks_start_one( 'PARSER', sub { call_parser(); cleanup(); } ); 
      forks_start_one( undef, sub { print "Testing :)\n; return 222 " } ); 
      }

    # wait for all children to finish
    forks_wait_all();

# DESCRIPTION

Data::Tools::Process::Forks provides a simple interface for managing multiple
forked child processes. It handles the common patterns of limiting concurrent
processes, tracking active children by name, and graceful shutdown via signals.

The module keeps track of running and completed children when the maximum fork 
count is reached, allowing new processes to start or wait for new open slot.

# FUNCTIONS

All functions are exported by default.

## Signal Handling

### forks\_setup\_signals()

Installs signal handlers for `INT` and `TERM` signals. When either signal is
received, the handler will send `TERM` to all child processes, wait for them
to exit, then terminate the parent process with exit code 111.

    forks_setup_signals();

This is optional and should typically be called early in the parent process 
before forking any children.

## Process Creation and Waiting

### forks\_start\_one( $name, $coderef, @args )

Forks a new child process to execute the given subroutine.

    my $pid = forks_start_one( 'worker', \&do_work, @work_args );

**Parameters:**

- `$name`

    Optional name for the forked process, used for identification. Defaults to
    `'*'` if not provided or undefined.

- `$coderef`

    Optional code reference to execute in the child. If provided, the child will
    execute this subroutine and exit with its return value as the exit code.
    If not provided, the function returns 0 in the child, allowing inline child
    code (see SYNOPSIS).

- `@args`

    Optional arguments passed to `$coderef` when executed in the child.

**Returns:**

- In the parent: the child's PID on success, or `'0E0'` (true but zero) on
fork failure. On fork failure and inline child prcesses, the parent will simply
skip the child code and try to fork again. To avoid high load, save the result
code and do something like:

        my $fr = forks_start_one();
        if( $fr eq '0E0' )
          {
          print "fork error [$!] sleeping\n";
          sleep 3;
          }
        next if $fr;  
        
        # forked child here
        exit 1;

- In the child (when no `$coderef` provided): 0

    To be sure code runs in the forked child process, return value must be checked
    like this:

        if( ! forks_start_one() )
          {
          # child here
          # must finish with exit!
          exit 2;
          }

    WARNING: return value should never be compared to 0, otherwise on fork errors, 
    child code will be executed in the parent process!

        if( forks_start_one() == 0 )
          {
          # WRONG! this will execute in the parent
          # must finish with exit!
          exit 2;
          }
        

**Note:** If the current number of active forks equals or exceeds the maximum
(see `forks_set_max()`), this function blocks until a child exits before
forking the new process.

### forks\_wait\_one( $non\_blocking )

Waits for one child process to exit.

    # blocking, return all child attributes (list context)
    my ( $pid, $exit_code, $signal, $name ) = forks_wait_one();
    
    # Non-blocking check, got pid only (scalar context)
    my $pid = forks_wait_one( 1 );

**Parameters:**

- `$non_blocking`

    If true, returns immediately if no child has exited (uses `WNOHANG`).
    If false or omitted, blocks until a child exits.

**Returns:**

In list context: `( $pid, $exit_code, $signal, $name )`

- `$pid`

    The process ID of the exited child.

- `$exit_code`

    The exit code returned by the child (high 8 bits of `$?`).

- `$signal`

    The signal that terminated the child, if any (low 7 bits of `$?`).

- `$name`

    The name assigned to the child when it was forked.

In scalar context: returns only `$pid`.

Returns an empty list if no children have exited (non-blocking mode) or if
there are no active children.

### forks\_wait\_all( $timeout )

Blocks until all active child processes have exited. Optional timeout in
seconds can be specified to avoid blocking. Avoiding blocking may give control
to the parent process when forked one has blocked for some reason.

    # block until all forks finished
    forks_wait_all(); 
    
    # or
    
    # wait 4 seconds for finished forks and return finished count
    my $c = forks_wait_all( 4 ); 
    

internally it calls forks\_wait\_one() until internal forked processes
count reached 0 or timeout reached.

## Process Signalling

### forks\_signal\_all( $signal )

Sends the specified signal to all active child processes.

    forks_signal_all( 'HUP' );
    forks_signal_all( 15 );      # SIGTERM by number

if signal is undef or empty parameter list, will do nothing and exit.

**Parameters:**

- `$signal`

    The signal name or number to send.

**Returns:** `undef` if no signal specified, otherwise the result of `kill()`.

### forks\_stop\_all()

Sends `TERM` signal to all active child processes.

    forks_stop_all();

Equivalent to `forks_signal_all( 'TERM' )`.

### forks\_kill\_all()

Sends `KILL` signal to all active child processes.

    forks_kill_all();

Equivalent to `forks_signal_all( 'KILL' )`. Use this for forceful termination
when children do not respond to `TERM`.

## Configuration

### forks\_set\_max( $max )

Sets the maximum number of concurrent child processes (slots).

    forks_set_max( 16 );
    

**Parameters:**

- `$max`

    Maximum number of concurrent forks. Values less than 1 are clamped to 4.

When `forks_start_one()` is called and the current fork count (slots) equals 
or exceeds this maximum, it will wait until a child exits before forking.

Default value is 4.

If called without parameters, will try to figure machine core count and set
it the same. Note that this works only on machines with /proc file system 
(i.e. Linux). if not Linux, /proc not mounted or other error will set to 8.

### forks\_get\_max()

Returns the current maximum fork limit.

    my $max = forks_get_max();

## Inspection

### forks\_count()

Returns the number of currently active child processes.

    my $active = forks_count();
    print "Running $active workers\n";

### forks\_pids()

Returns a list of PIDs for all active child processes.

    my @pids = forks_pids();

### forks\_names()

Returns a list of unique names assigned to active child processes.

    my @names = forks_names();

Note that multiple processes may share the same name; this returns only
unique names in use.

### forks\_set\_start\_wait\_to( $timeout )

This sets timeout for waiting for free slot when trying to start new fork but
maximum count has been reached. Setting $timeout to 0 will enable blocking,
i.e. forks\_start\_one() will wait until slot freed. If timeout reached
forks\_start\_one() will return '0E0' (zero but true) which is same as fork 
error.

# EXAMPLES

## Parallel Task Processing

    use Data::Tools::Process::Forks;

    forks_setup_signals();
    forks_set_max( 6 );

    my @files = glob( '*.dat' );

    for my $file ( @files )
      {
      forks_start_one( 
                       'processor', 
                       sub 
                          {
                          process_file( $file );
                          return 0;
                          }
                     );
      }

    forks_wait_all();
    print "All files processed\n";

## Worker Pool with Status Monitoring

    use Data::Tools::Process::Forks;

    forks_setup_signals();
    forks_set_max( 11 );

    # Start workers
    for my $id ( 1 .. 20 )
      {
      forks_start_one( "worker-$id", \&worker_task, $id );
      }

    # Monitor progress
    while( forks_count() > 0 )
      {
      my ( $pid, $exit, $sig, $name ) = forks_wait_one();
      if( $exit == 0 )
        {
        print "$name completed successfully\n";
        }
      else
        {
        print "$name failed with exit code $exit\n";
        }
      }

## Graceful Shutdown

    use Data::Tools::Process::Forks;

    forks_setup_signals();  # Handles INT/TERM automatically

    # Or manual shutdown:
    END
      {
      if( forks_count() > 0 )
        {
        print "Shutting down workers...\n";
        forks_stop_all();
        forks_wait_all();
        }
      }

# NOTES

- The module uses package-level variables to track state. Only one fork pool
can be managed per process but fork names can represent separate fork pools.

    This is really a design choice. This module was meant to be simple with
    minimum dependencies (only Perl core Exporter and POSIX). 

    For, possibly, more complex things you may check **Parralel::ForkManager** 
    on **CPAN**.

- Child processes reset the parent fork pool state so they can have own
fork process pool and use this module themselves.
- The `forks_start_one()` function may block indefinitely if child processes
do not exit and the maximum fork count is reached. To avoid this situation
`forks_set_start_wait_to()` can be used to set timeout for waiting for a free
slot to be available while trying to start new one:

        forks_set_start_wait_to( 4 );
        my $fr = forks_start_one();
        if( $fr eq '0E0' )
          {
          # either fork error occured
          # or timeout waiting for free slot reached
          ...
          }

# SEE ALSO

[Parallel::ForkManager](https://metacpan.org/pod/Parallel%3A%3AForkManager), [fork(2)](http://man.he.net/man2/fork), [waitpid(2)](http://man.he.net/man2/waitpid), [POSIX](https://metacpan.org/pod/POSIX)

# AUTHOR

    Vladi Belperchinov-Shabanski "Cade"
          <cade@noxrun.com> <cade@bis.bg> <cade@cpan.org>
    http://cade.noxrun.com/  

# COPYRIGHT AND LICENSE

Copyright (c) 2013-2026 Vladi Belperchinov-Shabanski "Cade"

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 2 of the License, or (at your
option) any later version.
# NAME

Data::Tools::Process::ForkPool - pools of forked processes with messaging

# SYNOPSIS

    use Data::Tools::Process::ForkPool;
    use Time::HiRes qw( sleep );

    # supervisor main loop
    while( ! $STOP )
      {
      # reap exited, read states, keep 2..16 workers, grow by 2 when all busy
      fpool_manage( 'WORKERS', \&worker, 2, 16, 2, @worker_args );

      for my $pid ( @pids_of_interest )
        {
        my $msg;
        while( fpool_recv_from( 'WORKERS', $pid, \$msg ) )
          {
          # one message from $pid in $msg
          }
        }
      sleep( 0.1 );
      }
    fpool_stop_all( 'WORKERS' );
    fpool_wait_all( 'WORKERS', 5 ); # wait up to 5 seconds for all to exit

    # forked worker
    sub worker
    {
      $SIG{ 'TERM' } = 'DEFAULT';
      fpool_iam_idle();
      while( 1 )
        {
        my $job;
        my $res = fpool_recv_super( \$job );
        return 0 unless defined $res; # supervisor gone
        if( ! $res ) { sleep( 0.1 ); next } # nothing yet
        fpool_iam_busy();
        fpool_send_super( "done: $job" );
        fpool_iam_idle();
        }
    }

# DESCRIPTION

A fork pool is a named set of forked processes running the same sub. The
supervisor keeps the pool between a minimum and a maximum count and grows
it when all forked processes report busy. Each forked process is connected
to the supervisor by its own [Net::Tools::Socket::Pair](https://metacpan.org/pod/Net%3A%3ATools%3A%3ASocket%3A%3APair) socket, used for
messages both ways and for the busy/idle state.

Pool names are case insensitive (upper cased). There may be many pools in
one supervisor, and a forked process may run its own (nested) pools.

All forked processes of a pool are placed in the pool's own process group,
which is used to reap and signal them. See the NOTES below and at the top
of the module source for the rules this implies (no setpgrp() or setsid()
in forked processes, no other fork()/wait() code in the supervisor, no
$SIG{ 'CHLD' } = 'IGNORE', signals are not propagated, etc.).

All functions are exported by default. Functions return undef on errors
like an unknown pool or pid. They do not set or clear `$SOCK_ERR`; it is
set only by the [Net::Tools::Socket::Pair](https://metacpan.org/pod/Net%3A%3ATools%3A%3ASocket%3A%3APair) calls they make, so check it
only after a socket call result (0 or undef from send/recv).

# MESSAGES

Messages are byte strings up to `$Net::Tools::Socket::Pair::MSG_MAX`
(128 KiB) long, sent and received whole. Data structures must be
serialized first. The messages "STATE:\*" and "STATE:-" are reserved for
fpool\_iam\_busy() and fpool\_iam\_idle().

Messages from forked processes are read by fpool\_update\_state() (called by
fpool\_manage()) into a per-process queue, from which fpool\_recv\_from()
returns them. Messages to forked processes are read directly by
fpool\_recv\_super().

$Data::Tools::Process::ForkPool::MSG\_QUEUE\_MAX limits each queue, 0 (the
default) means no limit. When a queue is full, its oldest messages are
discarded.

# SUPERVISOR FUNCTIONS

## fpool\_manage( $pool, \\&sub, $min, $max, $step, @args )

Creates the pool if needed, reaps exited processes (fpool\_wait\_all()),
reads states and messages (fpool\_update\_state()) and then forks new
processes running `\&sub->( @args )`:

    * up to $min, at least $step at a time
    * $step more, if all processes are busy and the count is below $max

$min defaults to 0, $max to $min (also when smaller than $min), $step to
int( $max / 10 ) + 1. The count may overshoot $max by up to $step - 1.

Should be called periodically from the supervisor's main loop. Returns the
count of new processes, or undef if \\&sub is not a code reference.

## fpool\_fork\_one( $pool, \\&sub, @args )

Forks one process in the pool, creates the pool if needed. Returns the new
pid in the supervisor, undef on error. Use it instead of fpool\_manage() for
an own growing policy, with fpool\_wait\_one(), fpool\_update\_state(),
fpool\_count() and fpool\_busy\_count().

The forked process never returns from it: it runs `\&sub->( @args )`
and exits with its return value. If \\&sub dies, the error is printed to
STDERR and it exits with 255. exit() runs END blocks and destructors in the
forked process too.

## fpool\_wait\_all( $pool, $timeout )

Reaps all already exited processes of the pool. Without $timeout (or with
0 or a negative one) it does not block. With $timeout (seconds) it also
waits for the rest to exit, checking once per second, and returns as soon
as the pool is empty or the timeout expires. Returns the count of reaped
processes, undef if none were reaped or there is no such pool. Unread
messages of a reaped process are discarded.

## fpool\_wait\_one( $pool )

Reaps one already exited process of the pool, does not block. Returns its
pid, or in list context ( $pid, $exit\_code, $signal, $status ), where
$status is the raw wait status ($?, with the core dump flag). Returns undef
(empty list) if none exited or there is no such pool.

## fpool\_update\_state( $pool )

Reads pending messages from the forked processes without waiting, up to 8
per process per call, the rest are read on the next call. "STATE:\*" and
"STATE:-" update the busy state of the process, other messages are queued
for fpool\_recv\_from(). Returns the busy count (0 for a pool which has not
forked yet), or undef if there is no such pool.

## fpool\_count( $pool ) / fpool\_busy\_count( $pool )

Return the count of processes in the pool and how many of them are busy,
as of the last fpool\_update\_state(). undef if there is no such pool.

## fpool\_stats( $pool )

Returns a text report: pool name, busy and process counts and the busy
state ('\*' busy, '-' idle) of each pid. undef if there is no such pool.

## fpool\_signal\_all( $pool, $signal )

Sends $signal ('TERM', 'HUP', 9, etc.) to all processes of the pool (its
process group). Returns the result of kill(), undef if there is no such
pool or it has no processes.

fpool\_stop\_all( $pool ) sends TERM, fpool\_kill\_all( $pool ) sends KILL.

## fpool\_send\_to( $pool, $pid, $data )

Sends message $data to the forked process $pid. Returns the
socketpair\_send() result: 1 sent, 0 not sent (queue full, etc.), undef
if the process closed its socket, or undef if there is no such pool or pid.

## fpool\_recv\_from( $pool, $pid, \\$data )

Takes the next queued message from the forked process $pid into $data.
Returns 1 for a message, 0 if the queue is empty, undef if there is no
such pool or pid. $data is set to undef whenever the result is not 1.
Dies (boom) if \\$data is not a scalar reference. Messages are queued only
by fpool\_update\_state() (and fpool\_manage()).

# FORKED PROCESS FUNCTIONS

These work only in a process forked by fpool\_fork\_one() or fpool\_manage(),
elsewhere they return undef.

## fpool\_send\_super( $data )

Sends message $data to the supervisor. Returns the socketpair\_send()
result: 1 sent, 0 not sent, undef if the supervisor is gone.

## fpool\_recv\_super( \\$data )

Reads the next message from the supervisor into $data, does not wait.
Returns the socketpair\_recv() result: 1 for a message, 0 if nothing is
waiting, undef if the supervisor is gone.

## fpool\_iam\_busy() / fpool\_iam\_idle()

Report the busy or idle state to the supervisor, as seen by
fpool\_busy\_count() and used by fpool\_manage() to grow the pool.

# NOTES

- Forked processes must not change their process group (setpgrp(), setsid(),
daemonizing), otherwise the pool never reaps or signals them.
- The pools should be the only means of forking in the supervisor. Other code
which calls wait() or waitpid( -1, ... ), and $SIG{ 'CHLD' } = 'IGNORE',
may reap the pool's processes behind its back. system(), qx// and piped
open() are safe.
- Signals are not propagated to the pools. The supervisor must catch the
signals it cares about and call fpool\_signal\_all(), fpool\_stop\_all() or
fpool\_kill\_all() for each pool. Forked processes inherit the supervisor's
%SIG and should set their own handlers first.
- If the supervisor dies without stopping the pools, forked processes keep
running. They see it as undef from fpool\_recv\_super() or a getppid()
change.
- Messages sent by a forked process right before it exits may be lost when
it is reaped. A process which must deliver a result should wait for an
acknowledge from the supervisor before it returns.
- Inherited DBI handles should have AutoInactiveDestroy set, END blocks meant
for the supervisor only should check $$.
- Works on Linux only, see [Net::Tools::Socket::Pair](https://metacpan.org/pod/Net%3A%3ATools%3A%3ASocket%3A%3APair).

# SEE ALSO

[Net::Tools::Socket::Pair](https://metacpan.org/pod/Net%3A%3ATools%3A%3ASocket%3A%3APair), [Net::Tools::Socket::Err](https://metacpan.org/pod/Net%3A%3ATools%3A%3ASocket%3A%3AErr),
[Data::Tools::Process::Forks](https://metacpan.org/pod/Data%3A%3ATools%3A%3AProcess%3A%3AForks)

# AUTHOR

    Vladi Belperchinov-Shabanski "Cade"
          <cade@noxrun.com>
    http://cade.noxrun.com/

# COPYRIGHT AND LICENSE

Copyright (c) 2026 Vladi Belperchinov-Shabanski "Cade"

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 2 of the License, or (at your
option) any later version.
