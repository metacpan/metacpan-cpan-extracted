use strict;
use Test::More 0.98 tests => 8;

use lib 'lib';

use Business::Tax::Withholding::JP;
my $tax;

$tax = Business::Tax::Withholding::JP->new( price => 10000);
$tax->date('2012-01-01');
is $tax->withholding(), 1000, "withholding before special tax";
is $tax->total(), 9800, "total before special tax";

$tax->date('2013-01-01');
is $tax->withholding(), 1021, "withholding with special tax";
is $tax->total(), 9779, "total with special tax";

$tax->date('2037-12-31');
is $tax->withholding(), 1021, "withholding with special tax";
is $tax->total(), 9779, "total with special tax";


$tax->date('2038-01-01');
is $tax->withholding(), 1000, "withholding without special tax";
is $tax->total(), 9800, "total without special tax";

done_testing;
