#!perl
use warnings;
use strict;
use Test::More tests => 6;
use Test::Bot::BasicBot::Pluggable;

my $bot = Test::Bot::BasicBot::Pluggable->new();

my $title = $bot->load("Title");
ok( $title, "loaded Title module" );

like( $bot->tell_direct("http://google.com"),
    qr/Google/, "got title of google ok" );

# test to make sure that Title.pm isn't eating urls.
ok( $bot->load("Infobot"), "loaded Infobot module" );
my $t = $bot->tell_direct("google is at http://google.com");
like( $t, qr/Google/, "got title of google ok" );
like( $t, qr/Okay/,   "infobot still there" );

$title->set( 'user_ignore_re' => 'perl' );
is( $bot->tell_direct("http://use.perl.org"), '', 'ignore_re works' );
