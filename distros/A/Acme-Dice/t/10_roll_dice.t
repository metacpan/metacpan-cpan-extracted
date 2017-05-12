# -*- perl -*-

# t/10_roll_dice.t - check operation of the roll_dice function

use Test::More tests => 7;

BEGIN { use_ok( 'Acme::Dice', qw(roll_dice) ); }

subtest 'basic parameter tests' => sub {
    plan tests => 7;

    # default roll should return a single d6
    my @rolls = roll_dice();
    ok( @rolls == 1, 'default roll has one die' );
    ok( $rolls[0] >= 1 && $rolls[0] <= 6, 'default consistent with a d6' );

    # check if undefined parameters are caught
    for (qw(dice sides favor bias)) {
        my $roll = eval { roll_dice( $_ => undef ); };
        ok( !defined($roll), "dies with undefined param: $_" );
    }

    # and be sure unknown params throw an error
    my $roll_u = eval { roll_dice( foo => 'bar' ); };
    ok( !defined($roll_u), 'dies with unknown parameter' );
};

subtest 'dice parameter values' => sub {
    plan tests => 15;

    for ( 1, 2, 3, 5, 100 ) {
        my $roll = roll_dice( dice => $_, sides => 1 );
        ok( $roll == $_, "good dice param: $_" );

        my @rolls = roll_dice( dice => $_ );
        ok( @rolls == $_, "$_ elements returned in list context" );
    }

    for ( -1, -0.5, 0, 1.5, 101 ) {
        my $roll = eval { roll_dice( dice => $_ ); };
        ok( !defined($roll), "dies with bad dice param: $_" );
    }
};

subtest 'sides parameter values' => sub {
    plan tests => 12;

    for ( 1, 2, 4, 6, 8, 10, 12, 100 ) {
        my $roll = roll_dice( sides => $_ );
        ok( defined($roll), "good sides param: $_" );
    }

    for ( -1, -0.5, 0, 0.5 ) {
        my $roll = eval { roll_dice( sides => $_ ); };
        ok( !defined($roll), "dies with bad sides param: $_" );
    }
};

subtest 'favor parameter values' => sub {
    plan tests => 15;

    for ( -1, -0.5, 1.5 ) {
        my $roll = eval { roll_dice( favor => $_ ); };
        ok( !defined($roll), "dies with bad favor param: $_" );
    }

    for my $sides ( 1 .. 12 ) {
        my $favor = $sides + 1;
        my $roll = eval { roll_dice( sides => $sides, favor => $favor ); };
        ok( !defined($roll), "dies with bad favor: $favor sides => $sides" );
    }
};

subtest 'bias parameter values' => sub {
    plan tests => 4;

    for ( -1, -0.4, 0.4, 101 ) {
        my $roll = eval { roll_dice( bias => $_ ); };
        ok( !defined($roll), "dies with bad bias param: $_" );
    }
};

subtest 'full range of possible values' => sub {
    plan tests => 36;

    # this could take a while, so only test d6 and hope it works for all
    for my $dice ( 1 .. 3 ) {

        # only test on a d6 for now
        my $min_val = $dice * 1;
        my $max_val = $dice * 6;

        my $rolls = {};
        for ( 1 .. ( $max_val * 100 ) ) {
            $rolls{ roll_dice( dice => $dice, sides => 6 ) }++;
        }

        for ( $min_val .. $max_val ) {
            ok( delete( $rolls{$_} ) > 0, 'value in expected range found' );
        }

        if ( keys( %{$rolls} ) ) {
            my $msg = join( ',', keys( %{$rolls} ) );
            fail("Unexpected values found: $msg");
        }
        else {
            pass("No values outside the expected range: $min_val .. $max_val");
        }
    }
};

done_testing();

exit;
