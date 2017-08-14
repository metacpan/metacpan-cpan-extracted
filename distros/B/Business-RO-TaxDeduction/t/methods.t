use strict;
use warnings;
use Test::Most;
use Scalar::Util qw(blessed);

use Business::RO::TaxDeduction;

subtest 'Test for round_to_int' => sub {
    foreach my $amount (qw(249 249.01 249.2 249.30 249.31 249.4 249.49)) {
        ok my $brtd = Business::RO::TaxDeduction->new(
            year    => 2016,
            vbl     => 999,
            persons => 0,
        ), "instance for $amount and 0 persons";
        is $brtd->_round_to_int($amount), 249, "round $amount to 249";
    }
    foreach my $amount (qw(249.5 249.59 249.6 249.99 250)) {
        ok my $brtd = Business::RO::TaxDeduction->new(
            year    => 2016,
            vbl     => 999,
            persons => 0,
        ), "instance for $amount and 0 persons";
        is $brtd->_round_to_int($amount), 250, "round $amount to 250";
    }
};

subtest 'Test for round_to_ten' => sub {
    my @test_data = (
        [ 0,      0 ],
        [ 0.1,    10 ],
        [ 9,      10 ],
        [ 10.1,   20 ],
        [ 15,     20 ],
        [ 149,    150 ],
        [ 249.49, 250 ],
        [ 251,    260 ],
    );
    foreach my $amount (@test_data) {
        ok my $brtd = Business::RO::TaxDeduction->new(
            year    => 2016,
            vbl     => 999,
            persons => 0,
        ), "new instance";
        is $brtd->_round_to_tens($amount->[0]), $amount->[1], "round to ten";
    }
};

subtest 'Test for failure and defaults' => sub {
    ok my $brtd = Business::RO::TaxDeduction->new(
        vbl     => 999,
    ), "new instance";
    is $brtd->tax_deduction, 300,
        "Tax for year 2016 (default),  persons 0 (default) and VBL = 999";

    throws_ok {
        Business::RO::TaxDeduction->new();
    }
    qr/Missing required arguments: vbl/,
        'throws: Missing required arguments: vbl';
};

done_testing;
