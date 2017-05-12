use Test::Modern;
use t::lib::Common qw(bp_v11 skip_unless_has_secret);

skip_unless_has_secret;

my $bp = bp_v11;

my $card_data = {
    number           => "5105105105105100",
    expiration_month => 12,
    expiration_year  => 2020,
};

subtest 'create a card' => sub {
    my $card1 = $bp->create_card( $card_data );
    ok $card1->{id} or diag explain $card1;

    my $card2 = $bp->get_card( $card1->{id} );
    is $card2->{id} => $card1->{id}, 'got correct card';
};

subtest 'add card to customer' => sub {
    my $cust = $bp->create_customer({ email => 'foo@bar.com' });
    my $card = $bp->create_card( $card_data );
    $card = $bp->add_card($card, customer => $cust);
    is $card->{links}{customer} => $cust->{id}
        or diag explain $card;
};

done_testing;
