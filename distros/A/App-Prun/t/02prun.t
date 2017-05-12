#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Script;
use Storable qw( thaw );
use Data::Dumper;
use App::Prun;
use Parallel::ForkManager;

plan tests => 23;

script_compiles( 'script/prun' );

my $stdout;
script_runs( ['script/prun', '--test-dump'], {exit => 255, stdout => \$stdout}, 'dump' );

my $obj;
ok (defined ($obj = thaw($stdout)), 'thaw return');

ok ($obj->pm->waitpid_blocking_sleep == 0, 'waitpid_blocking_sleep');
ok ($obj->pm->max_procs > 0, 'default --processes');
ok (!defined $obj->exit_on_failed_proc, 'default --exit-on-failure');
ok (!defined $obj->report_failed_procs, 'default --report-failed');

script_runs( [qw(script/prun --exit-on-failure --report-failed --processes=37 --test-dump)], {exit => 255, stdout => \$stdout}, 'dump' );
ok (defined ($obj = thaw($stdout)), 'thaw return');

#diag(Dumper($obj));
ok ($obj->pm->waitpid_blocking_sleep == 0, 'waitpid_blocking_sleep');
ok ($obj->pm->max_procs == 37, '--processes');
ok (defined $obj->exit_on_failed_proc, '--exit-on-failure');
ok (defined $obj->report_failed_procs, '--report-failed');

my $stderr;
script_runs( [qw(script/prun t/test_false)], {exit => 0, stdout => \$stdout, stderr => \$stderr}, 'false 1');
ok($stderr eq '', 'ignore failed process');

script_runs( [qw(script/prun -r t/test_false)], {exit => 0, stdout => \$stdout, stderr => \$stderr}, 'false 2');
ok($stderr =~ /failed with exit/, 'report failed process');

script_runs( [qw(script/prun -e t/test_false)], {exit => 1, stdout => \$stdout, stderr => \$stderr}, 'false 3');
ok($stderr eq '', "don't report failed process");

script_runs( [qw(script/prun -e -r t/test_false)], {exit => 1, stdout => \$stdout, stderr => \$stderr}, 'false 4');
ok($stderr =~ /failed with exit/, 'report failed process and exit');

script_runs( [qw(script/prun -e -r t/test_true)], {exit => 0, stdout => \$stdout, stderr => \$stderr}, 'true 1');
ok($stderr eq '', 'successful process');
