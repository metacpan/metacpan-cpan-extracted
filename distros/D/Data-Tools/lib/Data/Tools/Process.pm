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

our $VERSION = '1.47';

our @ISA    = qw( Exporter );
our @EXPORT = qw(
                  fork_exec_cmd
                  daemonize
                  
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
1;
