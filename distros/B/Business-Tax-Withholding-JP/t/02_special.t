use strict;
use Test::More 0.98 tests => 8;

use lib 'lib';

use Business::Tax::Withholding::JP;
my $calc;

$calc = Business::Tax::Withholding::JP->new( price => 10000);
$calc->date('2012-01-01');  # tax was 5%
is $calc->withholding(), 1000, "withholding before special tax";    # 1
is $calc->total(), 9500, "total before special tax";                # 2

$calc->date('2013-01-01');  # tax was 5%
is $calc->withholding(), 1021, "withholding with special tax";      # 3
is $calc->total(), 9479, "total with special tax";                  # 4

$calc->date('2037-12-31');  # tax will be 10%
is $calc->withholding(), 1021, "withholding with special tax";      # 5
is $calc->total(), 9979, "total with special tax";                  # 6


$calc->date('2038-01-01');  # special withholding will expire
is $calc->withholding(), 1000, "withholding without special tax";   # 7
is $calc->total(), 10000, "total without special tax";               # 8

done_testing;
