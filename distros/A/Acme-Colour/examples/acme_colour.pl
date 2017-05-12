#!perl
use strict;
use warnings;
use lib 'lib';
use Acme::Colour;

# light
my $c = Acme::Colour->new("black");
$c->add("red");      # $c->colour now red
$c->add("green");    # $c->colour now yellow
print "Light: black + red + green = " . $c->colour . "\n";

# pigment
$c = Acme::Colour->new("white");
$c->mix("cyan");       # $c->colour now cyan
$c->mix("magenta");    # $c->colour now blue
print "Pigment: white + cyan + magenta = " . $c->colour . "\n";

