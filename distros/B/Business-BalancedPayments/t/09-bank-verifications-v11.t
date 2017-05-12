
use Test::Modern;
use t::lib::Common qw(bp_v11 skip_unless_has_secret create_test_bank);

skip_unless_has_secret;

my $bp = bp_v11;

subtest 'bank account verifications' => sub {
    my $bank = create_test_bank;
    my $ver = $bp->create_bank_verification(bank_account => $bank);
    is $ver->{verification_status} => 'pending';
    is $ver->{attempts} => 0;

    my $fetched_ver = $bp->get_bank_verification($ver->{id});
    is $fetched_ver->{id} => $ver->{id};

    $ver = $bp->confirm_bank_verification($ver, amount_1 => 1, amount_2 => 1);
    is $ver->{verification_status} => 'succeeded';
};

done_testing;
