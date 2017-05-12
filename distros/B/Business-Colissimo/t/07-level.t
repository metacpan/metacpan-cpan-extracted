#! perl
#
# Tests for insurance and recommendation level

use strict;
use warnings;

use Test::More;
use Business::Colissimo;

# possible error messages
my $access_msg = qr{^Insurance/recommendation level not available in access mode};

my @level_tests =  ([{mode => 'access_f', level => '0'}, 0],
                    [{mode => 'access_f', level => '00'}, 1],
                    [{mode => 'access_f', level => '05'}, 0, $access_msg],
                    [{mode => 'access_f', level => '22'}, 0, $access_msg],
    );

plan tests => 2 * scalar @level_tests;

for (@level_tests) {
    my ($test_parms, $valid, $errmsg) = @$_;
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
        "Testing level $test_parms->{level} with mode $test_parms->{mode}")
        || diag "Unexpected result: $ret.";

    if ($msg) {
        $errmsg ||= qr{^Please provide valid value for insurance/recommendation level};
            
        # check for expected error message
        ok ($msg =~ m%$errmsg%,
            "Checking error message for level $test_parms->{level} with mode $test_parms->{mode}")
            || diag "Unexpected message: $msg.";
    }
    else {
        isa_ok($colissimo, 'Business::Colissimo');
    }
}

