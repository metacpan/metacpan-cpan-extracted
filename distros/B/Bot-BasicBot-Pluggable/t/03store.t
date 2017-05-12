use warnings;
use strict;
use Test::More tests => 3;
use Bot::BasicBot::Pluggable::Store;

my $store;

isa_ok(
    Bot::BasicBot::Pluggable::Store->new("Memory"),
    'Bot::BasicBot::Pluggable::Store::Memory'
);
isa_ok( Bot::BasicBot::Pluggable::Store->new( { type => "Memory" } ),
    'Bot::BasicBot::Pluggable::Store::Memory' );
isa_ok( Bot::BasicBot::Pluggable::Store->new(),
    'Bot::BasicBot::Pluggable::Store' );
