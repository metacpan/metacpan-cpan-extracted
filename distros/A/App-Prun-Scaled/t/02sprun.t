#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Script;
use Storable qw( thaw );
use App::Prun::Scaled;
use Parallel::ForkManager::Scaled;

plan tests => 39;

script_compiles( 'script/sprun' );

my $stdout;
script_runs( ['script/sprun', '--test-dump'], {exit => 255, stdout => \$stdout}, 'dump' );


my $obj;
ok (defined ($obj = thaw($stdout)), 'thaw return');

my $def;
ok ($def = Parallel::ForkManager::Scaled->new(), 'new Parallel::ForkManager::Scaled object');

for my $attr (qw( 
    initial_procs hard_min_procs hard_max_procs 
    idle_target idle_threshold update_frequency )) 
{
    ok ($def->$attr == $obj->pm->$attr, "default $attr");
}
ok ($obj->pm->waitpid_blocking_sleep == 0, 'waitpid_blocking_sleep');
ok (!defined $obj->exit_on_failed_proc, 'default --exit-on-failure');
ok (!defined $obj->report_failed_procs, 'default --report-failed');


my @args = qw( --exit-on-failure --report-failed --initial-procs=37 --test-dump );
my $opts = {exit => 255, stdout => \$stdout};

script_runs( ['script/sprun', @args ], $opts, 'dump' );
ok (defined ($obj = thaw($stdout)), 'thaw return');

ok ($obj->pm->waitpid_blocking_sleep == 0, 'waitpid_blocking_sleep');
ok ($obj->pm->initial_procs == 37, '--initial-procs');
ok (defined $obj->exit_on_failed_proc, '--exit-on-failure');
ok (defined $obj->report_failed_procs, '--report-failed');


@args = qw( 
    --exit-on-failure --report-failed --test-dump 
    --initial-procs=5 --min-procs=3 --max-procs=7
    --idle-target=17 --idle-threshold=2 --update-frequency=0
);
script_runs( ['script/sprun', @args], $opts, 'dump2' );
ok (defined ($obj = thaw($stdout)), 'thaw return 2');

ok (defined $obj->exit_on_failed_proc, '--exit-on-failure');
ok (defined $obj->report_failed_procs, '--report-failed');
ok ($obj->pm->initial_procs == 5,    '--initial-procs 2');
ok ($obj->pm->hard_min_procs == 3,   '--min-procs 2');
ok ($obj->pm->hard_max_procs == 7,   '--max-procs 2');
ok ($obj->pm->idle_target == 17,     '--idle-target 2');
ok ($obj->pm->idle_threshold == 2,   '--idle-threshold 2');
ok ($obj->pm->update_frequency == 0, '--update-frequency 2');

my $stderr;
script_runs( [qw(script/sprun t/test_false)], {exit => 0, stdout => \$stdout, stderr => \$stderr}, 'false 1');
ok($stderr eq '', 'ignore failed process');

script_runs( [qw(script/sprun -r t/test_false)], {exit => 0, stdout => \$stdout, stderr => \$stderr}, 'false 2');
ok($stderr =~ /failed with exit/, 'report failed process');

script_runs( [qw(script/sprun -e t/test_false)], {exit => 1, stdout => \$stdout, stderr => \$stderr}, 'false 3');
ok($stderr eq '', "don't report failed process");

script_runs( [qw(script/sprun -e -r t/test_false)], {exit => 1, stdout => \$stdout, stderr => \$stderr}, 'false 4');
ok($stderr =~ /failed with exit/, 'report failed process and exit');

script_runs( [qw(script/sprun -e -r t/test_true)], {exit => 0, stdout => \$stdout, stderr => \$stderr}, 'true 1');
ok($stderr eq '', 'successful process');
