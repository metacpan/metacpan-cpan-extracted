#!perl

use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::Bot::BasicBot::Pluggable;
 
my $bot = Test::Bot::BasicBot::Pluggable->new();
 
my $load = $bot->load("WikiLink");
ok( $load, "loaded WikiLink module" );
 
like( $bot->tell_direct("stuff [[Perl]]"),
    qr!wiki/Perl!, "got link to [[Perl]] ok" );

done_testing();
