use strict;
use Test::More 0.98 tests => 33;

use lib 'lib';

use Business::Tax::Withholding::JP;
my $calc = Business::Tax::Withholding::JP->new( no_wh => 1 );

note "without withholding---";

$calc->price(10000);
is $calc->net(), 10000, "net";                                      # 1
is $calc->subtotal(), 10000, "subtotal";                            # 2
is $calc->tax(), 1000, "tax";                                        # 3
is $calc->full(), 11000, "full";                                    # 4
is $calc->withholding(), 0, "withholding";                          # 5
is $calc->total(), 11000, "total";                                  # 6

$calc->amount(0);
is $calc->net(), 10000, "net";                                      # 7
is $calc->subtotal(), 0, "subtotal with amount 0";                  # 8
is $calc->tax(), 0, "tax with amount 0";                            # 9
is $calc->full(), 0, "full with amount 0";                          #10
is $calc->withholding(), 0, "withholding amount 0";                 #11
is $calc->total(), 0, "total with amount 0";                        #12

$calc->amount(2);
is $calc->subtotal(), 20000, "subtotal with amount 2";              #13
is $calc->tax(), 2000, "tax with amount 2";                         #14
is $calc->full(), 22000, "full with amount 2";                      #15
is $calc->withholding(), 0, "withholding amount 2";                 #16
is $calc->total(), 22000, "total with amount 2";                    #17

my $calc = Business::Tax::Withholding::JP->new();

note "with withholding---";

$calc->price(10000);
is $calc->net(), 10000, "net";                                      #18
is $calc->subtotal(), 10000, "subtotal";                            #19
is $calc->tax(), 1000, "tax";                                        #20
is $calc->full(), 11000, "full";                                    #21
is $calc->withholding(), 1021, "withholding";                       #22
is $calc->total(), 9979, "total";                                   #23

$calc->amount(0);
is $calc->subtotal(), 0, "subtotal with amount 0";                  #24
is $calc->tax(), 0, "tax with amount 0";                            #25
is $calc->full(), 0, "full with amount 0";                          #26
is $calc->withholding(), 0, "withholding amount 0";                 #27
is $calc->total(), 0, "total with amount 0";                        #28

$calc->amount(2);
is $calc->subtotal(), 20000, "subtotal with amount 2";              #29
is $calc->tax(), 2000, "tax with amount 2";                         #30
is $calc->full(), 22000, "full with amount 2";                      #31
is $calc->withholding(), 2042, "withholding amount 2";              #32
is $calc->total(), 19958, "total with amount 2";                    #33

done_testing;
