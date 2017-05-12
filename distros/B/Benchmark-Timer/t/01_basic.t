# ========================================================================
# t/01_basic.t - ensure that Benchmark::Timer object can be created, used
# Andrew Ho (andrew@zeuscat.com)
#
# Test basic usage of the Benchmark::Timer library.
#
# Because timings will differ from system to system, we can't actually
# test the functionality of the module. So we just test that all the
# method calls run without triggering exceptions.
#
# This script is intended to be run as a target of Test::Harness.
#
# Last modified April 20, 2001
# ========================================================================

use strict;
use Test::More tests => 11;
use Time::HiRes;

# 1
BEGIN { use_ok( 'Benchmark::Timer') }

# ------------------------------------------------------------------------
# Basic tests of the Benchmark::Timer library.

my $t = Benchmark::Timer->new;

#2
ok(defined $t, 'Construct Benchmark::Timer');

$t->reset;

#3
ok(1, 'reset');

my $before = [ Time::HiRes::gettimeofday ];    # minimize overhead

$t->start('tag');
while (Time::HiRes::tv_interval($before, [Time::HiRes::gettimeofday]) == 0) {
  Time::HiRes::usleep(10);
}
$t->stop;

#4
ok(1, 'Start/stop a tag');

my $result = $t->result('tag');

#5
isnt($result, 0, 'Nonzero single result');

my @results = $t->results;

#6
is(scalar @results, 2, 'Multiple results');

my $results = $t->results;

#7
isa_ok($results, 'ARRAY', 'Array ref results');

my @data = $t->data('tag');

#8
is(scalar @data, 1, 'tag data array');

my $data = $t->data('tag');

#9
isa_ok($data, 'ARRAY', 'Array ref data');

@data = $t->data;

#10
is(scalar @data, 2, 'all tags data array');

$data = $t->data;

#11
isa_ok($data, 'ARRAY', 'all tags data ref');


# ========================================================================
__END__
