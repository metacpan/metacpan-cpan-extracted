#!perl

use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::Bot::BasicBot::Pluggable;
 
my $bot = Test::Bot::BasicBot::Pluggable->new();
 
my $load = $bot->load("SubReddit");
ok( $load, "loaded SubReddit module" );
 
like( $bot->tell_direct("/r/perl"),
    qr!reddit.com/r/perl!, "got link to /r/perl ok" );

like( $bot->tell_direct("hlagh r/iama wibble"),
	qr!r/iama -- I Am A!, "got link to r/IAmA with title" );

done_testing();
