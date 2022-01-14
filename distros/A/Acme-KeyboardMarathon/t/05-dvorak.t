use Acme::KeyboardMarathon;
use Test::Simple tests => 3;
use strict;

my $text = "Included in this distribution is an example script (marathon.pl) that can";
my $km = new Acme::KeyboardMarathon;
my $dist = $km->distance($text);

ok( $dist == 123, "Should be 123: $dist" ); 

$km = new Acme::KeyboardMarathon (layout => "dvorak");
$dist = $km->distance($text);

ok( $dist == 89, "Should be 89: $dist" ); 

$km = new Acme::KeyboardMarathon (layout => "qwerty");
$dist = $km->distance($text);

ok( $dist == 123, "Should be 123: $dist" ); 
