use strict;
use warnings;
use Test::More;

my $CLASS = 'Acme::Mitey::Cards::Card';

require_ok( $CLASS );

my $card = new_ok $CLASS, [ reverse => 'black' ];

is( $card->reverse, 'black' );

can_ok( $card, 'to_string' );

my ( $warning );
my $str = do {
	local $SIG{__WARN__} = sub { $warning = shift };
	$card->to_string;
};

is( $str, 'XX' );
like( $warning, qr/to_string needs to be implemented/ );

done_testing;
