#!/usr/bin/perl
##############################################################################
#
#  Data::Tools test suite -- Data::Tools::Process::Forks
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
use File::Temp qw( tempdir );
use Data::Tools;
use Data::Tools::Process::Forks;

ok( defined $Data::Tools::Process::Forks::VERSION, 'Data::Tools::Process::Forks loaded' );

my $TMP = tempdir( 'data-tools-t6-XXXXXX', TMPDIR => 1, CLEANUP => 1 );

##############################################################################
# max forks count
##############################################################################

forks_reset_state();
is( forks_get_max(), 4, 'forks_reset_state() restores the default max' );

forks_set_max( 7 );
is( forks_get_max(), 7, 'forks_set_max()/forks_get_max()' );

forks_set_max( 0 );
is( forks_get_max(), 4, 'forks_set_max() clamps values below 1 to 4' );

forks_set_max( -3 );
is( forks_get_max(), 4, 'forks_set_max() clamps negative values to 4' );

forks_set_max(); # no argument: use machine core count
cmp_ok( forks_get_max(), '>', 0, 'forks_set_max() without argument uses the machine core count' );

cmp_ok( Data::Tools::Process::Forks::__get_max_machine_core_count(), '>', 0,
        '__get_max_machine_core_count() returns a positive count' );

forks_reset_state();
is( forks_count(), 0, 'forks_count() is zero with no forks running' );
is_deeply( [ forks_pids()  ], [], 'forks_pids() is empty with no forks running' );
is_deeply( [ forks_names() ], [], 'forks_names() is empty with no forks running' );

##############################################################################
# forks_start_one() with a callback sub
##############################################################################

forks_reset_state();
forks_set_max( 4 );
forks_set_start_wait_to( 5 );

my $pid = forks_start_one( 'worker', sub { file_save( "$TMP/worker.$$", 'done' ); return 0; } );

cmp_ok( $pid, '>', 0, 'forks_start_one() returns the child pid to the parent' );
is( forks_count(), 1, 'forks_count() sees the started fork' );
is_deeply( [ forks_pids() ], [ $pid ], 'forks_pids() lists the child pid' );
is_deeply( [ forks_names() ], [ 'worker' ], 'forks_names() lists the fork name' );

my ( $wpid, $exit, $xsig, $name ) = forks_wait_one();
is( $wpid, $pid,      'forks_wait_one() returns the reaped pid' );
is( $exit, 0,         'forks_wait_one() returns the exit code' );
is( $xsig, 0,         'forks_wait_one() returns no exit signal' );
is( $name, 'worker',  'forks_wait_one() returns the fork name' );
is( forks_count(), 0, 'forks_count() is zero after the fork was reaped' );

ok( -e "$TMP/worker.$pid", 'forks_start_one() ran the callback in the child' );

##############################################################################
# exit codes are passed through
##############################################################################

forks_reset_state();
my $epid = forks_start_one( 'exiter', sub { return 3 } );
my ( undef, $eexit ) = forks_wait_one();
is( $eexit, 3, 'forks_start_one() child exits with the callback return value' );

##############################################################################
# forks_wait_all()
##############################################################################

forks_reset_state();
forks_set_max( 4 );

forks_start_one( "job$_", sub { return 0 } ) for 1 .. 3;
is( forks_count(), 3, 'forks_start_one() started all requested forks' );

my $stopped = forks_wait_all();
is( $stopped, 3,      'forks_wait_all() returns the number of reaped forks' );
is( forks_count(), 0, 'forks_wait_all() reaped everything' );

##############################################################################
# forks_start_one() blocks at the max count
##############################################################################

forks_reset_state();
forks_set_max( 2 );
forks_set_start_wait_to( 0 ); # blocking wait

my @pids;
push @pids, forks_start_one( undef, sub { return 0 } ) for 1 .. 5;

is( scalar( grep { $_ eq '0E0' } @pids ), 0, 'forks_start_one() blocks instead of failing when at max' );
cmp_ok( forks_count(), '<=', 2, 'forks_start_one() never exceeds the max fork count' );

forks_wait_all();
is( forks_count(), 0, 'all forks reaped' );

##############################################################################
# unnamed forks
##############################################################################

forks_reset_state();
forks_start_one( undef, sub { return 0 } );
is_deeply( [ forks_names() ], [ '*' ], 'forks_start_one() names unnamed forks "*"' );
forks_wait_all();

##############################################################################
# signalling running forks
##############################################################################

forks_reset_state();
forks_set_max( 4 );

forks_start_one( 'sleeper', sub { $SIG{ 'TERM' } = sub { exit 0 }; sleep 30; return 0 } ) for 1 .. 2;
is( forks_count(), 2, 'two sleepers started' );

forks_stop_all();
my $terminated = forks_wait_all();
is( $terminated, 2,   'forks_stop_all() terminated all forks' );
is( forks_count(), 0, 'no forks left after forks_stop_all()' );

forks_reset_state();
forks_start_one( 'ignorer', sub { $SIG{ 'TERM' } = 'IGNORE'; sleep 30; return 0 } );
forks_kill_all();
is( forks_wait_all(), 1, 'forks_kill_all() kills forks that ignore TERM' );

is( forks_signal_all(), undef, 'forks_signal_all() without a signal returns undef' );

##############################################################################
# forks_wait_one() with nothing to wait for
##############################################################################

forks_reset_state();
is_deeply( [ forks_wait_one() ], [], 'forks_wait_one() returns empty list when there is nothing to reap' );

##############################################################################
# signal handlers
##############################################################################

my $old_int  = $SIG{ 'INT'  };
my $old_term = $SIG{ 'TERM' };
forks_setup_signals();
is( ref( $SIG{ 'INT'  } ), 'CODE', 'forks_setup_signals() installs an INT handler' );
is( ref( $SIG{ 'TERM' } ), 'CODE', 'forks_setup_signals() installs a TERM handler' );
$SIG{ 'INT'  } = $old_int  || 'DEFAULT';
$SIG{ 'TERM' } = $old_term || 'DEFAULT';

##############################################################################

done_testing();
