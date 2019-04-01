use strict;
use Test::More 0.98 tests => 11;

use lib 'lib';

use Business::Tax::Withholding::JP;
my $tax = Business::Tax::Withholding::JP->new( no_wh => 1 );

$tax->price(10000);
is $tax->net(), 10000, "net";                                       # 1
is $tax->tax(), 800, "tax";                                         # 2
is $tax->full(), 10800, "full";                                     # 3
is $tax->withholding(), 0, "withholding";                           # 4
is $tax->total(), 10800, "total";                                   # 5

$tax->price(1000000);
is $tax->withholding(), 0, "withholding with 1,000,000";            # 6
is $tax->total(), 1080000, "total with 1,000,000";                  # 7

$tax->price(1111111);
is $tax->tax(), 88888, "tax with 1,111,111";                        # 8
is $tax->full(), 1199999, "full with 1,111,111";                    # 9
is $tax->withholding(), 0, "withholding with 1,111,111";            #10
is $tax->total(), 1199999, "total with 1,111,111";                  #11

done_testing;
