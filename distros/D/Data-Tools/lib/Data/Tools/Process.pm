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

use POSIX;
use Data::Tools;

our $VERSION = '1.52';

our @ISA    = qw( Exporter );
our @EXPORT = qw(
                  fork_exec_cmd
                  daemonize
                  
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
#       open file names for stdout/err
#

sub daemonize
{
  my %opt = @_;

  hash_uc_ipl( \%opt );
  
  umask( $opt{ 'UMASK' } || 0077 );
  
  my $pid = fork();
  die "fatal: daemonize: fork step 1 failed: $!\n" unless defined $pid;
  exit() if $pid;
  
  POSIX::setsid() or die "fatal: daemonize: cannot detach controlling process/terminal\n";
  
  # SVR4-second-fork policy
  $pid = fork();
  die "fatal: daemonize: fork final step failed: $!\n" unless defined $pid;
  exit() if $pid;

  my $chdir = $opt{ 'CHDIR' } || '/';
  chdir( $chdir ) or die "fatal: daemonize: cannot chdir to [$chdir]\n";

  # close all open fds
  my $openmax = POSIX::sysconf( &POSIX::_SC_OPEN_MAX );
  $openmax = 1024 if $openmax <= 0;
  POSIX::close( $_ ) for 0 .. $openmax - 1;

  # reopen std
  open( STDIN,  '+>', '/dev/null' ) or die "fatal: daemonize: cannot reopen STDIN to /dev/null\n";
  open( STDOUT, "+>&STDIN" ) or die "fatal: daemonize: cannot reopen STDOUT to /dev/null\n";
  open( STDERR, "+>&STDIN" ) or die "fatal: daemonize: cannot reopen STDERR to /dev/null\n";

  return 1;
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
changes the current directory, closes all open file descriptors and reopens
STDIN, STDOUT and STDERR to /dev/null.

Options are:

  CHDIR => $path   # directory to change to, default is '/'
  UMASK => $umask  # umask to set, default is 0077

Returns 1 in the resulting daemon process. The original process and the
intermediate one exit() and never return. Dies on any of the steps failing.

  NOTE: all open file descriptors are closed, including any files, sockets
        or database handles opened before the call.

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

  git@github.com:cade-vs/perl-data-tools.git

  git clone git://github.com/cade-vs/perl-data-tools.git

=head1 AUTHOR

  Vladi Belperchinov-Shabanski "Cade"
        <cade@noxrun.com> <cade@bis.bg> <cade@cpan.org>
  http://cade.noxrun.com/


=cut

##############################################################################
1;
