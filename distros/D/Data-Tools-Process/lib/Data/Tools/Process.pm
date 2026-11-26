##############################################################################
#
#  Data::Tools::Process process control and utilities
#  Copyright (c) 2013-2024 Vladi Belperchinov-Shabanski "Cade"
#        <cade@noxrun.com> <cade@bis.bg> <cade@cpan.org>
#  http://cade.noxrun.com/
#
#  GPL
#
##############################################################################
package Data::Tools::Process;
use strict;
use Exporter;

use Cwd;
use POSIX;
use Data::Tools;

our $VERSION = '1.60';

our @ISA    = qw( Exporter );
our @EXPORT = qw(
                  fork_exec_cmd
                  daemonize
                  daemonize_here

                  pidfile_kill_and_remove
                  pidfile_create
                  pidfile_remove
                );

##############################################################################

sub fork_exec_cmd
{
  my $cmd = shift;

  my $pid = fork();
  return undef if ! defined $pid; # fork failed
  return $pid if $pid;            # master process here
  exec $cmd;                      # sub process here
  exit;                           # if sub exec fails...
}

##############################################################################

# TODO:
#       pidfile
#       lock pidfile to ensure single process
#

sub daemonize
{
  my %opt = @_;

  hash_uc_ipl( \%opt );

  umask( $opt{ 'UMASK' } // 0077 );

  my $pid = fork();
  die "fatal: daemonize: fork step 1 failed due to {$!}\n" unless defined $pid;
  POSIX::_exit( 0 ) if $pid; # avoid END{} and all destructors

  POSIX::setsid() or die "fatal: daemonize: cannot detach controlling process/terminal due to {$!}\n";

  # SVR4-second-fork policy
  $pid = fork();
  die "fatal: daemonize: fork final step failed: $!\n" unless defined $pid;
  POSIX::_exit( 0 ) if $pid; # avoid END{} and all destructors

  my $chdir = $opt{ 'CHDIR' } // '/';
  chdir( $chdir ) or die "fatal: daemonize: cannot chdir to [$chdir] due to {$!}\n";

  # close stdio perl handles first, otherwise perl reopens a std handle on
  # the fd number it had before, which may not be its 0/1/2
  close( STDIN );
  close( STDOUT );
  close( STDERR );

  # free fds 0/1/2 (any handle may hold them), so the reopened stdio gets
  # them, close all other fds only if requested:
  # CLOSE_ALL_FDS == 1 closes up to _SC_OPEN_MAX but not above 1024 (it can be
  # huge under high ulimit and the loop gets slow), 2..1024 -- uncapped,
  # above 1024 -- the value itself is the cap
  my $closemax = 3;
  if( my $close_all = $opt{ 'CLOSE_ALL_FDS' } )
    {
    $closemax = POSIX::sysconf( &POSIX::_SC_OPEN_MAX );
    $closemax = 1024 if $closemax <= 0;
    my $cap = $close_all == 1 ? 1024 : $close_all > 1024 ? $close_all : undef;
    $closemax = $cap if $cap and $closemax > $cap;
    }
  POSIX::close( $_ ) for 0 .. $closemax - 1;

  my ( $out_mode, $out_file ) = defined $opt{ 'STDOUT' } ? ( '>>', $opt{ 'STDOUT' } ) : ( '+>&', 'STDIN' );
  my ( $err_mode, $err_file ) = defined $opt{ 'STDERR' } ? ( '>>', $opt{ 'STDERR' } ) : ( '+>&', 'STDIN' );

  # reopen stdio, open() takes the lowest free fd, so the order here gives
  # STDIN=0, STDOUT=1, STDERR=2, which C code and child processes expect.
  # STDOUT/STDERR files are appended, relative names are under CHDIR
  open( STDIN,  '+>', '/dev/null' ) or die "fatal: daemonize: cannot reopen STDIN to [/dev/null] due to {$!}\n";
  open( STDOUT, $out_mode, $out_file ) or die "fatal: daemonize: cannot reopen STDOUT to ($out_mode $out_file) in [$chdir] due to {$!}\n";
  open( STDERR, $err_mode, $err_file ) or die "fatal: daemonize: cannot reopen STDERR to ($err_mode $err_file) in [$chdir] due to {$!}\n";

  return 1;
}

sub daemonize_here
{
  my $cwd = getcwd() // die "cannot get current working directory\n";
  return daemonize( CHDIR => $cwd, @_ );
}

##############################################################################

# pidfile_kill_and_remove( $pid_file_name, signal_list... )
# args:
#    $pid_file_name -- file name of the pid file
#    signal_list    -- list of signals to be sent to the pidfile's pid
#                      if value has 's' at the end it is considered sleep time
#                      in seconds between the signals. all are executed in the
#                      given order:
#                      15, 5s, 15, 2s, 9 -- send two TERM signals with 5 seconds
#                      sleep and then wait 2 seconds and send KILL
# returns:
#    * undef if $pid_file_name does not exist
#    * 1 if signals has been sent and $pid_file_name file removed

sub pidfile_kill_and_remove
{
  my $fname   = shift;
  my @siglist = @_;

  return undef unless -e $fname;

  @siglist = ( 15 ) unless @siglist;

  my $opid = int( file_load( $fname ) );

  for( @siglist )
    {
    sleep( $_ ), next if s/s$//;
    kill( $_, $opid );
    }

  unlink( $fname );

  return 1;
}

# pidfile_create( $pid_file_name, STALE_CHECK => 1 )
#    STALE_CHECK is optional and will try to check if existing process is
#                running with the same pid file name
#
# returns:
#    * undef for success
#    * negative for error
#    * positive (non-zero) for existing running process pid
# errors:
#    * -1 cannot create pidfile or was created just before we try

sub pidfile_create
{
  my $fname = shift;
  my %opt   = @_;

  hash_uc_ipl( \%opt );

  my $opid = int( file_load( $fname ) );
  unlink( $fname ) if ( $opid < 1 ) or ( $opt{ 'STALE_CHECK' } and ! kill( 0, $opid ) );

  return $opid if -e $fname;

  dir_path_ensure( file_path( $fname ) );
  return -1 unless sysopen my $fh, $fname, O_CREAT | O_EXCL | O_RDWR, 0600;

  print $fh $$;

  close $fh;

  return undef;
}

sub pidfile_remove
{
  my $fname = shift;

  unlink( $fname ) if $fname;
  return undef;
}


##############################################################################

=pod


=head1 NAME

  Data::Tools::Process provides set of functions for process control,
  forking, daemonizing and pid files handling.

=head1 SYNOPSIS

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

=head1 FUNCTIONS

=head2 fork_exec_cmd( $command )

Forks and exec()s $command in the child process.

Returns:

  * the child process pid in the parent process
  * undef if fork() failed

The child never returns. $command is passed to exec() as a single string,
so it is subject to the usual shell handling of exec().

=head2 daemonize( %options )

Detaches the current process from the controlling terminal and turns it into
a daemon: forks, calls POSIX::setsid(), forks again (SVR4 second fork policy),
changes the current directory, closes STDIN, STDOUT and STDERR (and all other
open file descriptors if CLOSE_ALL_FDS is set) and reopens them as file
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
use full paths (or daemonize_here()). STDOUT and STDERR may name the same
file. STDOUT is buffered, set autoflush on it if log lines must show up
immediately.

CLOSE_ALL_FDS => 1 closes file descriptors up to the system limit
(sysconf _SC_OPEN_MAX), but not above 1024, since under a high open files
limit (ulimit -n) closing them one by one can take a long time. A value
from 2 to 1024 (e.g. CLOSE_ALL_FDS => 2) closes up to the system limit
uncapped. A value above 1024 is used as the cap instead of 1024, e.g.
CLOSE_ALL_FDS => 65536 closes up to the system limit, but not above 65536.

Returns 1 in the resulting daemon process. The original process and the
intermediate one leave with POSIX::_exit(0) and never return, so END blocks
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

=head2 daemonize_here( %options )

The same as daemonize() but the CHDIR default is the current working
directory instead of '/', so the daemon stays where it was started and
relative STDOUT/STDERR file names are relative to it. All daemonize()
options are accepted, an explicit CHDIR overrides the default.

=head2 pidfile_create( $pid_file_name, %options )

Creates $pid_file_name and writes the pid of the current process in it. The
file is created with O_EXCL, so two processes racing for the same pid file
cannot both succeed. Missing directories on the way are created.

Options are:

  STALE_CHECK => 1  # take over the pid file if its process is not running

Returns:

  * undef on success, the pid file now holds our pid
  * a positive pid if the pid file exists and holds a running process
  * -1 if the pid file cannot be created

A pid file which does not hold a valid (positive) pid is always considered
stale and is replaced, regardless of STALE_CHECK.

=head2 pidfile_kill_and_remove( $pid_file_name, @signal_list )

Sends the given signals to the pid found in $pid_file_name and then removes
the file. @signal_list defaults to a single TERM (15).

A list item ending with 's' is not a signal but a sleep time in seconds. All
items are processed in the given order, so:

  pidfile_kill_and_remove( $fname, 15, '5s', 15, '2s', 9 );

sends TERM, waits 5 seconds, sends TERM again, waits 2 seconds, sends KILL.

Returns:

  * undef if $pid_file_name does not exist
  * 1 if the signals have been sent and the pid file removed

=head2 pidfile_remove( $pid_file_name )

Removes $pid_file_name. Returns undef.

=head1 REQUIRED MODULES

Data::Tools::Process uses:

  * POSIX
  * Data::Tools

=head1 GITHUB REPOSITORY

  git@github.com:cade-vs/perl-data-tools-process.git

  git clone git://github.com/cade-vs/perl-data-tools-process.git

=head1 AUTHOR

  Vladi Belperchinov-Shabanski "Cade"
        <cade@noxrun.com> <cade@bis.bg> <cade@cpan.org>
  http://cade.noxrun.com/


=cut

##############################################################################
1;
