use strict;
use warnings;
use Test::More;

use Acme::Mitey::Cards::Card;

my $CLASS = 'Acme::Mitey::Cards::Hand';

require_ok( $CLASS );

my $hand = new_ok $CLASS, [ owner => 'Alice' ];

is( $hand->count, 0 );
is( $hand->owner, 'Alice' );

push @{ $hand->cards }, Acme::Mitey::Cards::Card->new;

is( $hand->count, 1 );

done_testing;
