use Acme::KeyboardMarathon;
use Test::Simple tests => 4;
use strict;

my $text = "THE QUICK BROWN FOX JUMPS OVER THE LAZY DOG!";
my $km = new Acme::KeyboardMarathon;
my $dist = $km->distance($text);

ok( $dist == 144, "Should be 146: $dist" ); 

$text = "The quick brown fox jumps over the lazy dog.";
$km = new Acme::KeyboardMarathon;
$dist = $km->distance($text);

ok( $dist == 72, "Should be 72: $dist" ); 

$text = 'The ~`@#$, %^&*(, ={}|[], ?,./ fox jumps over the )-_+, \:";\'<>, dog.';
$km = new Acme::KeyboardMarathon;
$dist = $km->distance($text);

ok( $dist == 210, "Should be 210: $dist" ); 

$text = " \t\n";
$km = new Acme::KeyboardMarathon;
$dist = $km->distance($text);

ok( $dist == 7, "Should be 7: $dist" );
