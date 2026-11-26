#!/usr/bin/perl
##############################################################################
#
#  Data::Tools test suite -- Data::Tools::Process
#  Copyright (c) 2013-2026 Vladi Belperchinov-Shabanski "Cade"
#        <cade@noxrun.com> <cade@bis.bg> <cade@cpan.org>
#  http://cade.noxrun.com/
#
#  GPL
#
##############################################################################
use strict;
use lib 'lib', '../lib';
use Test::More;
use POSIX qw( WNOHANG );
use File::Temp qw( tempdir );
use Data::Tools;
use Data::Tools::Process;

ok( defined $Data::Tools::Process::VERSION, 'Data::Tools::Process loaded' );

my $TMP = tempdir( 'data-tools-t5-XXXXXX', TMPDIR => 1, CLEANUP => 1 );

##############################################################################
# fork_exec_cmd()
##############################################################################

my $marker = "$TMP/forked.txt";
my $pid = fork_exec_cmd( "echo forked > '$marker'" );

ok( defined $pid, 'fork_exec_cmd() returns a pid' );
cmp_ok( $pid, '>', 0, 'fork_exec_cmd() returns the child pid to the parent' );

is( waitpid( $pid, 0 ), $pid, 'fork_exec_cmd() child is reapable' );
is( $?, 0, 'fork_exec_cmd() child exited cleanly' );
is( file_load( $marker ), "forked\n", 'fork_exec_cmd() actually ran the command' );

##############################################################################
# pidfile_create() / pidfile_remove()
##############################################################################

my $PIDFILE = "$TMP/test.pid";

is( pidfile_create( $PIDFILE ), undef, 'pidfile_create() returns undef when it created the pidfile' );
ok( -e $PIDFILE,                       'pidfile_create() created the file' );
is( file_load( $PIDFILE ), $$,         'pidfile_create() stored our pid' );

is( pidfile_create( $PIDFILE ), $$, 'pidfile_create() returns the running pid when pidfile exists' );

is( pidfile_remove( $PIDFILE ), undef, 'pidfile_remove() returns undef' );
ok( ! -e $PIDFILE,                     'pidfile_remove() removed the file' );

# pidfile_create() creates missing directories on the way
my $DEEP = "$TMP/deep/er/test.pid";
pidfile_create( $DEEP );
ok( -e $DEEP, 'pidfile_create() creates the pidfile path' );
pidfile_remove( $DEEP );

##############################################################################
# stale pidfile handling
##############################################################################

# find a pid that is (almost certainly) not running: fork, reap, reuse its pid
my $dead = fork();
if( $dead == 0 ) { exit 0 }
waitpid( $dead, 0 );

file_save( $PIDFILE, $dead );
is( pidfile_create( $PIDFILE ), $dead,
    'pidfile_create() without STALE_CHECK reports the stale pid' );

file_save( $PIDFILE, $dead );
is( pidfile_create( $PIDFILE, STALE_CHECK => 1 ), undef,
    'pidfile_create() with STALE_CHECK takes over a stale pidfile' );
is( file_load( $PIDFILE ), $$, 'pidfile_create() with STALE_CHECK stored our pid' );
pidfile_remove( $PIDFILE );

# a pidfile holding garbage is considered stale too
file_save( $PIDFILE, 'not a pid' );
is( pidfile_create( $PIDFILE ), undef, 'pidfile_create() replaces a pidfile without a valid pid' );
pidfile_remove( $PIDFILE );

##############################################################################
# pidfile_kill_and_remove()
##############################################################################

is( pidfile_kill_and_remove( "$TMP/no-such.pid" ), undef,
    'pidfile_kill_and_remove() returns undef for a missing pidfile' );

my $child = fork();
if( $child == 0 )
  {
  $SIG{ 'TERM' } = sub { exit 0 };
  sleep 30;
  exit 0;
  }

file_save( $PIDFILE, $child );
is( pidfile_kill_and_remove( $PIDFILE, 15 ), 1, 'pidfile_kill_and_remove() returns 1' );
ok( ! -e $PIDFILE, 'pidfile_kill_and_remove() removed the pidfile' );

# give the child a moment to act on the signal
my $reaped;
for ( 1 .. 50 )
  {
  $reaped = waitpid( $child, WNOHANG );
  last if $reaped == $child;
  select( undef, undef, undef, 0.1 );
  }
is( $reaped, $child, 'pidfile_kill_and_remove() signalled the process in the pidfile' );

##############################################################################
# daemonize() is not exercised here -- it detaches the process and closes all
# file descriptors, which would take the test harness down with it
##############################################################################

ok( defined &Data::Tools::Process::daemonize, 'daemonize() is available' );

##############################################################################

done_testing();
