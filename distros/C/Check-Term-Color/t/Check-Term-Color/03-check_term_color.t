use strict;
use warnings;

use Check::Term::Color qw(check_term_color);
use Test::More 'tests' => 8;
use Test::NoWarnings;

# Test.
my $ret = check_term_color({'NO_COLOR' => 1});
is($ret, 0, 'Get check value (0 - NO_COLOR env variable).');

# Test.
$ret = check_term_color({'COLOR' => 'always'});
is($ret, 1, 'Get check value (1 - COLOR env variable set to \'always\').');

# Test.
$ret = check_term_color({'COLOR' => 'yes'});
is($ret, 1, 'Get check value (1 - COLOR env variable set to \'yes\').');

# Test.
$ret = check_term_color({'COLOR' => 'never'});
is($ret, 0, 'Get check value (0 - COLOR env variable set to \'never\').');

# Test.
$ret = check_term_color({'COLOR' => 'no'});
is($ret, 0, 'Get check value (0 - COLOR env variable set to \'no\').');

# Test.
$ret = check_term_color({'COLOR' => '1'});
is($ret, 1, 'Get check value (1 - COLOR env variable set to \'1\').');

# Test.
$ret = check_term_color({});
is($ret, 0, 'Get check value (0 - No COLOR and NO_COLOR env variables).');
