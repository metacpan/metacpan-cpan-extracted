# -*- perl -*-

# t/20_roll_craps.t - check operation of the roll_craps function

use Test::More tests => 4;

BEGIN { use_ok( 'Acme::Dice', qw(roll_craps) ); }

subtest 'basic parameter tests' => sub {
    plan tests => 8;

    my @rolls = roll_craps();
    ok( @rolls == 2, 'default roll has two die' );
    ok( $rolls[0] >= 1 && $rolls[0] <= 6, 'default consistent with a d6' );
    ok( $rolls[1] >= 1 && $rolls[1] <= 6, 'default consistent with a d6' );

    # check if unknown parameters are caught
    for (qw(dice sides favor foo)) {
        my $roll = eval { roll_craps( $_ => undef ); };
        ok( !defined($roll), "dies with unknown param: $_" );
    }

    # and be sure an undefined param throws an error
    my $roll_u = eval { roll_craps( bias => undef ); };
    ok( !defined($roll_u), 'dies with undefined bias parameter' );
};

subtest 'bias parameter values' => sub {
    plan tests => 2;

    for ( -1, 101 ) {
        my $roll = eval { roll_craps( bias => $_ ); };
        ok( !defined($roll), "dies with bad bias param: $_" );
    }
};

subtest 'full range of possible values' => sub {
    plan tests => 12;

    my $min_val = 2;
    my $max_val = 12;

    my $rolls = {};
    for ( 1 .. 360 ) {
        $rolls{ roll_craps() }++;
    }

    for ( $min_val .. $max_val ) {
        ok( delete( $rolls{$_} ) > 0, 'value in expected range found' );
    }

    if ( keys( %{$rolls} ) ) {
        my $msg = join( ',', keys( %{$rolls} ) );
        fail("Unexpected Value(s) found: $msg");
    }
    else {
        pass("No values outside the expected range: $min_val .. $max_val");
    }
};

done_testing();

exit;
