use strict;
use Test::More 0.98 tests => 15;

use lib 'lib';

use Business::Tax::Withholding::JP;
my $tax = Business::Tax::Withholding::JP->new();

$tax->price(10000);
is $tax->net(), 10000, "net";                                       # 1
is $tax->tax(), 800, "tax";                                         # 2
is $tax->full(), 10800, "full";                                     # 3
is $tax->withholding(), 1021, "withholding";                        # 4
is $tax->total(), 9779, "total";                                    # 5

$tax->price(1000000);
is $tax->withholding(), 102100, "withholding with 1,000,000";       # 6
is $tax->total(), 977900, "total with 1,000,000";                   # 7

$tax->price(2000000);
is $tax->withholding(), 306300, "withholding with 2,000,000";       # 8
is $tax->total(), 1853700, "total with 2,000,000";                  # 9

$tax->price(3000000);
is $tax->withholding(), 510500, "withholding with 3,000,000";       #10
is $tax->total(), 2729500, "total with 3,000,000";                  #11

$tax->price(1111111);
is $tax->tax(), 88888, "tax with 1,111,111";                        #12
is $tax->full(), 1199999, "full with 1,111,111";                    #13
is $tax->withholding(), 124788, "withholding with 1,111,111";       #14
is $tax->total(), 1075211, "total with 1,111,111";                  #15
done_testing;
