use Test::Modern;
use t::lib::Common qw(bp_v11 skip_unless_has_secret create_card);

skip_unless_has_secret;

my $bp = bp_v11;
my $card = create_card;

subtest 'create and capture hold' => sub {
    my $hold = $bp->create_hold({ amount => 123 }, card => $card);
    is $hold->{amount} => 123;

    $hold = $bp->get_hold($hold->{id});
    is $hold->{amount} => 123;

    my $debit = $bp->capture_hold($hold);
    is $debit->{amount} => 123;
};

subtest 'partially capture a hold' => sub {
    my $hold = $bp->create_hold({ amount => 400 }, card => $card);
    my $debit = $bp->capture_hold($hold, debit => { amount => 200 });
    is $debit->{amount} => 200;
};

subtest 'create and void hold' => sub {
    my $hold = $bp->create_hold({ amount => 123 }, card => $card);
    $hold = $bp->void_hold($hold);
    ok $hold->{voided_at} or diag explain $hold;
};

subtest 'create hold with bad params' => sub {
    ok exception { $bp->create_hold() };
    ok exception { $bp->create_hold({ amount => 1 }) };
    ok exception { $bp->create_hold({ amount => 1 }, card => 4) };
    like exception { $bp->create_hold({ foo => 1 }, card => $card) },
        qr/the hold amount is missing/i;
    like exception { $bp->create_hold({ amount => 1 }, card => {}) },
        qr/the card href is missing/i;
};

done_testing;
