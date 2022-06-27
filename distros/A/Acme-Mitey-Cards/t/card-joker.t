use strict;
use warnings;
use Test::More;

my $CLASS = 'Acme::Mitey::Cards::Card::Joker';

require_ok( $CLASS );

my $card = new_ok $CLASS, [ reverse => 'black' ];

is( $card->reverse, 'black' );
is( $card->to_string, 'J#' );

done_testing;
