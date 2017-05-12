use Test::Modern;
use JSON qw(from_json);
use t::lib::Common qw(
    bp_v11 skip_unless_has_secret create_card create_test_bank
);

skip_unless_has_secret;

my $bp = bp_v11;

subtest 'create a credit to a bank' => sub {
    my $bank = create_test_bank;
    my $credit = $bp->create_credit({ amount => 123 }, bank_account => $bank);
    is $credit->{amount} => 123;

    $credit = $bp->get_credit($credit->{id});
    is $credit->{amount} => 123;
};

subtest 'create a credit to a card' => sub {
    my $exc = exception {
        $bp->create_credit({ amount => 123 }, card => create_card);
    };
    is $exc->code => 409;
    is from_json($exc->content)->{errors}[0]{category_code},
        "funding-destination-not-creditable";
};

done_testing;

