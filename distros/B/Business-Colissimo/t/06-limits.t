#! perl
#
# Tests for various limits and restrictions

use strict;
use warnings;

use Test::More;
use Business::Colissimo;

my @zip_tests = ([{mode => 'access_f', postal_code => 12345}, 1],
                 [{mode => 'access_f', postal_code => 0}, 0],
                 [{mode => 'access_f', postal_code => 1234}, 0],
                 [{mode => 'access_f', postal_code => 123456}, 0],
                 [{mode => 'expert_f', postal_code => 12345}, 1],
                 [{mode => 'expert_f', postal_code => 0}, 0],
                 [{mode => 'expert_f', postal_code => 1234}, 0],
                 [{mode => 'expert_f', postal_code => 123456}, 0],
                 [{mode => 'expert_om', postal_code => 12345}, 1],
                 [{mode => 'expert_om', postal_code => 0}, 0],
                 [{mode => 'expert_om', postal_code => 1234}, 0],
                 [{mode => 'expert_om', postal_code => 123456}, 0],
                 [{mode => 'expert_i', postal_code => 12345}, 1],
                 [{mode => 'expert_i', postal_code => 0}, 0],
                 [{mode => 'expert_i', postal_code => 12}, 1],
                 [{mode => 'expert_i', postal_code => 1234567890}, 1],
                 [{mode => 'expert_i', postal_code => 12345678901}, 0],
    );

plan tests => 2 * scalar @zip_tests;

for (@zip_tests) {
    my ($test_parms, $valid) = @$_;
    my ($colissimo, $ret, $msg);

    eval {
        $colissimo = Business::Colissimo->new(%$test_parms);
    };

    if ($@) {
        $msg = $@;
        $ret = 0;
    }
    else {
        $ret = 1;
    }

    # check for expected result
    ok ($ret == $valid, 
        "Testing postal code $test_parms->{postal_code} with mode $test_parms->{mode}")
        || diag "Unexpected result: $ret.";

    if ($msg) {
        # check for expected error message
        ok ($msg =~ /^Please provide valid postal code/, "Checking error message for postal code $test_parms->{postal_code} with mode $test_parms->{mode}")
            || diag "Unexpected message: $msg.";
    }
    else {
        isa_ok($colissimo, 'Business::Colissimo');
    }
}
