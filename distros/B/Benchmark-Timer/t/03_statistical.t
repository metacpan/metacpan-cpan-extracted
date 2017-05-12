# ========================================================================
# t/03_statistical.t - ensure that Benchmark::Timer object can be created,
# used for statistical measurement
# David Coppit <david@coppit.org>
#
# Test statistical usage of the Benchmark::Timer library.
#
# Because timings will differ from system to system, we can't actually
# test the functionality of the module. So we just test that all the
# method calls run without triggering exceptions.
#
# This script is intended to be run as a target of Test::Harness.
#
# Last modified September 2, 2004
# ========================================================================

use strict;
use Test::More;

# ------------------------------------------------------------------------

unless (eval 'require Statistics::PointEstimation')
{
  plan skip_all => 'Statistics::PointEstimation is not installed';
  exit;
}

plan tests => 4;

# ------------------------------------------------------------------------

# Statistical tests of the Benchmark::Timer library.

use Benchmark::Timer;
use Time::HiRes qw( usleep );

my $t = Benchmark::Timer->new(minimum => 3, confidence => 97.5, error => .5);

# 1
ok(defined $t, 'Created Benchmark::Timer');

my $time = time;

while( $t->need_more_samples('tag') )
{
  $t->start('tag');

  sleep 1;

  $t->stop('tag');

  print $t->report;
}

# 2
ok(1, 'Finished collecting data');

my $result = $t->result('tag');

# 3
ok(defined $result, 'Statistical results');

my @data = $t->data('tag');

use Data::Dumper;
print "Data:\n", Dumper \@data;

# 4
ok(@data >= 3, 'More than 2 trials');

# ========================================================================
__END__
