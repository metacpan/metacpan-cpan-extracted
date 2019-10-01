use strict;
use Test::More 0.98 tests => 30;
use Time::Piece;
my $t = localtime();

use lib 'lib';

use Business::Tax::Withholding::JP;
my $calc = Business::Tax::Withholding::JP->new();
my $date = $t->strptime( $calc->date(), '%Y-%m-%d' );

SKIP: {
    skip 'Tax was up to 10%', 15 if $date >= $t->strptime( '2019-10-01', '%Y-%m-%d' );
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
}

SKIP: {
    skip 'Tax is still 8%', 15 if $date < $t->strptime( '2019-10-01', '%Y-%m-%d' );
    $calc->price(10000);
    is $calc->net(), 10000, "net";                                      #16
    is $calc->tax(), 1000, "tax";                                       #17
    is $calc->full(), 11000, "full";                                    #18
    is $calc->withholding(), 1021, "withholding";                       #19
    is $calc->total(), 9979, "total";                                   #20

    $calc->price(1000000);
    is $calc->withholding(), 102100, "withholding with 1,000,000";      #21
    is $calc->total(), 997900, "total with 1,000,000";                  #22

    $calc->price(2000000);
    is $calc->withholding(), 306300, "withholding with 2,000,000";      #23
    is $calc->total(), 1893700, "total with 2,000,000";                 #24

    $calc->price(3000000);
    is $calc->withholding(), 510500, "withholding with 3,000,000";      #25
    is $calc->total(), 2789500, "total with 3,000,000";                 #26

    $calc->price(1111111);
    is $calc->tax(), 111111, "tax with 1,111,111";                      #27
    is $calc->full(), 1222222, "full with 1,111,111";                   #28
    is $calc->withholding(), 124788, "withholding with 1,111,111";      #29
    is $calc->total(), 1097434, "total with 1,111,111";                 #30
}

done_testing;
