use strict;
use warnings;
use Test::More;

use Acme::Mitey::Cards::Card;

my $CLASS = 'Acme::Mitey::Cards::Set';

require_ok( $CLASS );

my $set = new_ok $CLASS;

is( $set->count, 0 );

push @{ $set->cards }, Acme::Mitey::Cards::Card->new;

is( $set->count, 1 );

my $set2 = $set->take( 1 );

is( $set->count, 0 );
is( $set2->count, 1 );

my $set3 = $set->take( 0 );

is( $set->count, 0 );
is( $set3->count, 0 );

my $e = do {
	local $@;
	eval { $set->take( 1 ) };
	$@;
};

like(
	$e,
	qr/Not enough cards/,
	'Exception thrown if you try to take too many cards',
);

done_testing;
