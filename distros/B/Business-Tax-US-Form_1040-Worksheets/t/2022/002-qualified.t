# t/2022/002-qualified.t
use 5.14.0;
use warnings;
use Test::More;

use Business::Tax::US::Form_1040::Worksheets qw(
    qualified_dividends_capital_gains_tax
);
#use Data::Dump qw(dd pp);

note('qualified_dividends_capital_gains_tax()');
my ($tax);
{
    local $@;
    eval { $tax = qualified_dividends_capital_gains_tax([]); };
    like( $@, qr/Argument to qualified_dividends_capital_gains_tax\(\) must be hashref/,
        "Got expected error message: bad argument to qualified_dividends_capital_gains_tax()"
    );
}

{
    local $@;
    my $k = 'l1000';
    eval { $tax = qualified_dividends_capital_gains_tax({ $k => 789.10 }); };
    like( $@, qr/Invalid value for 'status1' element/,
        "Got expected error message: bad argument '$k' to qualified_dividends_capital_gains_tax()"
    );
}

{
    local $@;
    my $v = 'foo';
    eval { $tax = qualified_dividends_capital_gains_tax({ status1 => undef }); };
    like( $@, qr/Invalid value for 'status1' element/,
        "Got expected error message: 'status1' not defined"
    );
}

{
    local $@;
    my $v = 'foo';
    eval { $tax = qualified_dividends_capital_gains_tax({
            status1 => $v,
            status2 => 'single',
        }); };
    like( $@, qr/Invalid value for 'status1' element/,
        "Got expected error message: bad argument '$v' for 'status1'"
    );
}

{
    local $@;
    my $v = 'foo';
    eval { $tax = qualified_dividends_capital_gains_tax({
            status1 => 'single_or_married_sep',
            status2 => $v,
        }); };
    like( $@, qr/Invalid value for 'status2' element/,
        "Got expected error message: bad argument '$v' for 'status2'"
    );
}

{
    local $@;
    eval { $tax = qualified_dividends_capital_gains_tax({
            status2 => 'single',
        }); };
    like( $@, qr/Invalid value for 'status1' element/,
        "Got expected error message: 'status1' not defined"
    );
}

{
    local $@;
    eval { $tax = qualified_dividends_capital_gains_tax({
            status1 => 'single_or_married_sep',
        }); };
    like( $@, qr/Invalid value for 'status2' element/,
        "Got expected error message: 'status2' not defined"
    );
}

{
    local $@;
    my $invalid = 'status3';
    eval { $tax = qualified_dividends_capital_gains_tax({
            status1 => 'single_or_married_sep',
            status2 => 'single',
            $invalid => 'foo',
        }); };
    like( $@, qr/Invalid element in hashref passed to qualified_dividends_capital_gains_tax\(\)/,
        "Got expected error message: '$invalid' is not valid"
    );
}

##########

note("single_or_married_sep / single");
{
    my $inputs = {
        l15 => 7000.00,
        l3a => 4900.00,
        sD  => 1600.00,
        status1 => 'single_or_married_sep',
        status2 => 'single',
        filing_year => 2022,
    };
    my $expect = {
        5 =>    500.00,
        18 =>   0,
        21 =>   0,
        1 =>    7000.00,
    };
    my $results = qualified_dividends_capital_gains_tax($inputs);
    for my $j (18, 21, 1) {
        cmp_ok($results->[$j], '==', $expect->{$j},
            "Got expected result for line $j");
    }
    my $k = 5;
    cmp_ok(abs($results->[$k] - $expect->{$k}), '<', 1,
        "Result for line $k, $results->[$k] is within expected tolerance from $expect->{$k}"
    );
}

note("single_or_married_sep / single");
{
    my $inputs = {
        l15 => 7000.00,                     # Form 1040, line 15
        l3a => 4900.00,                     # Form 1040, line 3a
        sD  => 1600.00,                     # If filing Schedule D, enter smaller
                                            #  of Schedule D, line 15 or 16;
                                            #  if not, enter Form 1040, line 7.
        status1 => 'single_or_married_sep', # Permissible values:
                                            #  single_or_married_sep
                                            #  married
                                            #  head_of_household
        status2 => 'single',                # Permissible values:
                                            #  single
                                            #  married_sep
                                            #  married
                                            #  head_of_household
        filing_year => 2022,
    };
    my $expect = {
        5 =>    500.00,
        18 =>   0,
        21 =>   0,
        1 =>    7000.00,
    };
    my $results = qualified_dividends_capital_gains_tax($inputs);
    for my $j (18, 21, 1) {
        cmp_ok($results->[$j], '==', $expect->{$j},
            "Got expected result for line $j");
    }
    my $k = 5;
    cmp_ok(abs($results->[$k] - $expect->{$k}), '<', 1,
        "Result for line $k, $results->[$k] is within expected tolerance from $expect->{$k}"
    );
}

note("single_or_married_sep / married_sep");
{
    my $inputs = {
        l15 => 7000.00,
        l3a => 4900.00,
        sD  => 1600.00,
        status1 => 'single_or_married_sep',
        status2 => 'married_sep',
        filing_year => 2022,
    };
    my $expect = {
        5 =>    500.00,
        18 =>   0,
        21 =>   0,
        1 =>    7000.00,
    };
    my $results = qualified_dividends_capital_gains_tax($inputs);
    for my $j (18, 21, 1) {
        cmp_ok($results->[$j], '==', $expect->{$j},
            "Got expected result for line $j");
    }
    my $k = 5;
    cmp_ok(abs($results->[$k] - $expect->{$k}), '<', 1,
        "Result for line $k, $results->[$k] is within expected tolerance from $expect->{$k}"
    );
}

note("married / married");
{
    my $inputs = {
        l15 => 7000.00,
        l3a => 4900.00,
        sD  => 1600.00,
        status1 => 'married',
        status2 => 'married',
        filing_year => 2022,
    };
    my $expect = {
        5 =>    500.00,
        18 =>   0,
        21 =>   0,
        1 =>    7000.00,
    };
    my $results = qualified_dividends_capital_gains_tax($inputs);
    for my $j (18, 21, 1) {
        cmp_ok($results->[$j], '==', $expect->{$j},
            "Got expected result for line $j");
    }
    my $k = 5;
    cmp_ok(abs($results->[$k] - $expect->{$k}), '<', 1,
        "Result for line $k, $results->[$k] is within expected tolerance from $expect->{$k}"
    );
}

note("head_of_household / head_of_household");
{
    my $inputs = {
        l15 => 7000.00,
        l3a => 4900.00,
        sD  => 1600.00,
        status1 => 'head_of_household',
        status2 => 'head_of_household',
        filing_year => 2022,
    };
    my $expect = {
        5 =>    500.00,
        18 =>   0,
        21 =>   0,
        1 =>    7000.00,
    };
    my $results = qualified_dividends_capital_gains_tax($inputs);
    for my $j (18, 21, 1) {
        cmp_ok($results->[$j], '==', $expect->{$j},
            "Got expected result for line $j");
    }
    my $k = 5;
    cmp_ok(abs($results->[$k] - $expect->{$k}), '<', 1,
        "Result for line $k, $results->[$k] is within expected tolerance from $expect->{$k}"
    );
}

note("worksheet line 1 <= worksheet line 4");
{
    my $inputs = {
        l15 => 7000.00,
        l3a => 4900.00,
        sD  => 2200.00,
        status1 => 'single_or_married_sep',
        status2 => 'single',
        filing_year => 2022,
    };
    my $expect = {
        5 =>    0,
        18 =>   0,
        21 =>   0,
        1 =>    7000.00,
    };
    my $results = qualified_dividends_capital_gains_tax($inputs);
    for my $j (18, 21, 1) {
        cmp_ok($results->[$j], '==', $expect->{$j},
            "Got expected result for line $j");
    }
    my $k = 5;
    cmp_ok(abs($results->[$k] - $expect->{$k}), '<', 1,
        "Result for line $k, $results->[$k] is within expected tolerance from $expect->{$k}"
    );
}

note("worksheet line 14 > worksheet line 15");
{
    my $inputs = {
        l15 => 600000,
        l3a => 100000,
        sD  => 400000,
        status1 => 'single_or_married_sep',
        status2 => 'single',
        filing_year => 2022,
    };
    my $expect = {
        5 =>    100000,
        18 =>   53962.50,
        21 =>   28050,
        1 =>    600000,
    };
    my $results = qualified_dividends_capital_gains_tax($inputs);
    for my $j (18, 21, 1) {
        cmp_ok($results->[$j], '==', $expect->{$j},
            "Got expected result for line $j");
    }
    my $k = 5;
    cmp_ok(abs($results->[$k] - $expect->{$k}), '<', 1,
        "Result for line $k, $results->[$k] is within expected tolerance from $expect->{$k}"
    );
}

note("required numeric field implicitly zero");
{
    my $inputs = {
        l15 => 7000.00,
        #l3a => 4900.00,                    # no qualified dividends
        sD  => 1600.00,
        status1 => 'single_or_married_sep',
        status2 => 'single',
        filing_year => 2022,
    };
    my $expect = {
        5 =>    5400.00,
        18 =>   0,
        21 =>   0,
        1 =>    7000.00,
    };
    my $results = qualified_dividends_capital_gains_tax($inputs);
    for my $j (18, 21, 1) {
        cmp_ok($results->[$j], '==', $expect->{$j},
            "Got expected result for line $j");
    }
    my $k = 5;
    cmp_ok(abs($results->[$k] - $expect->{$k}), '<', 1,
        "Result for line $k, $results->[$k] is within expected tolerance from $expect->{$k}"
    );
}

done_testing();
