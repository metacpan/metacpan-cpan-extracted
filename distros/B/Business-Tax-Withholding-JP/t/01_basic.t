use strict;
use Test::More 0.98 tests => 15;

use lib 'lib';

use Business::Tax::Withholding::JP;
my $calc = Business::Tax::Withholding::JP->new();

$calc->price(10000);
is $calc->net(), 10000, "net";                                      # 1
is $calc->tax(), 800, "tax";                                        # 2
is $calc->full(), 10800, "full";                                    # 3
is $calc->withholding(), 1021, "withholding";                       # 4
is $calc->total(), 9779, "total";                                   # 5

$calc->price(1000000);
is $calc->withholding(), 102100, "withholding with 1,000,000";      # 6
is $calc->total(), 977900, "total with 1,000,000";                  # 7

$calc->price(2000000);
is $calc->withholding(), 306300, "withholding with 2,000,000";      # 8
is $calc->total(), 1853700, "total with 2,000,000";                 # 9

$calc->price(3000000);
is $calc->withholding(), 510500, "withholding with 3,000,000";      #10
is $calc->total(), 2729500, "total with 3,000,000";                 #11

$calc->price(1111111);
is $calc->tax(), 88888, "tax with 1,111,111";                       #12
is $calc->full(), 1199999, "full with 1,111,111";                   #13
is $calc->withholding(), 124788, "withholding with 1,111,111";      #14
is $calc->total(), 1075211, "total with 1,111,111";                 #15
done_testing;
