use Test::More tests => 1;
use DateTime::Format::Pg 0.02;

# This test fails when nanosecond is not converted properly to an integer. This
# happens when the fractional part of timestamp is .254182 - got this number by
# experiment.
{
  my $dt = DateTime::Format::Pg->parse_datetime('2017-05-02 12:39:10.254182+00');
  cmp_ok($dt->nanosecond(), '==', 254182000, 'nanosecond as a number');
}
