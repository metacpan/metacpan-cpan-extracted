use Test::Modern;
use t::lib::Common qw(bp_v11 skip_unless_has_secret create_test_bank);

skip_unless_has_secret;

my $bp = bp_v11;

subtest 'debit a bank' => sub {
    my $bank = create_test_bank;

    # Need the verify bank first to make it "debitable"
    my $ver = $bp->create_bank_verification(bank_account => $bank);
    $bp->confirm_bank_verification($ver, amount_1 => 1, amount_2 => 1);

    my $debit = $bp->create_debit({ amount => 124 }, bank => $bank);
    is $debit->{amount} => 124;

    $debit = $bp->get_debit($debit->{id});
    is $debit->{amount} => 124;
};

done_testing;
