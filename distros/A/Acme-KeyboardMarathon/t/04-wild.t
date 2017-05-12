use Acme::KeyboardMarathon;
use File::Slurp;
use Test::Simple tests => 1;
use strict;

my $text = read_file('t/wild.txt');
my $km = new Acme::KeyboardMarathon;
my $dist = $km->distance($text);

ok( $dist == 314862, "Should be 314862, got $dist" );
