#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More 0.62 tests => 10;
use Test::Warn;

BEGIN {
    use_ok( 'Acme::AXP::Utils' ) || print "Bail out!\n";
}

# Check that subroutines are defined
ok( defined &Acme::AXP::Utils::sum, 'Util::sum is defined' );

# Check that sum works as expected
is( Acme::AXP::Utils::sum( 1, 2, 3 ), 6, 'Sum positive integers' );
is( Acme::AXP::Utils::sum( -1, 4, -7 ), -4, 'Sum positive and negative integers' );
is( Acme::AXP::Utils::sum( 0.3, 5, -1.6 ), 3.7, 'Sum decimals' );
is( Acme::AXP::Utils::sum( '6', '7' ), 13, 'Numbers as strings' );
is( Acme::AXP::Utils::sum( 1 ), 1, 'Single item list' );
is( Acme::AXP::Utils::sum(), 0, 'Zero item list' );
is( no_warnings( \&Acme::AXP::Utils::sum, '3', '6ix', 'one' ), 9, 'Ignore characters' );

warning_like { Acme::AXP::Utils::sum( 'y' ) } qr/^Argument "y" isn't numeric in addition/, "Non-numeric warning";

sub no_warnings {
	my $f = shift;
	local $SIG{__WARN__} = sub {};
	return $f->( @_ );
}
