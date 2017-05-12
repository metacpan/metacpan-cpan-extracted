#!/usr/bin/perl -w

use strict;
use Test::Exception;
use Test::More tests => 73;

BEGIN { use_ok('Acme::Colour'); }

# Basic test
ok(1, "Basic test");

my $c = Acme::Colour->new();
isa_ok($c, 'Acme::Colour', "should get Acme::Colour object");
is($c->colour, "white", "should get white object");

# Test additive colour
ok(1, "Test additive colour");

$c = Acme::Colour->new("black");
ok($c, "should get colour");
is("$c", "black", "should get black");
$c->add("red");
is($c->colour, "red", "black and red is red");
$c->add("green");
is($c->colour, "yellow", "red and green is yellow");
$c->add("blue");
is($c->colour, "white", "yellow and blue is white");
$c->add("white");
is($c->colour, "white", "can't get whiter than white");

# Test factors
$c = Acme::Colour->new("black");
ok($c, "should get colour");
is("$c", "black", "should get black");
$c->add("red", 0.5);
like($c->colour, qr/dark ?red/, "black and 0.5 red is dark red");

$c = Acme::Colour->new("black");
ok($c, "should get colour");
is("$c", "black", "should get black");
$c->add("red");
is($c->colour, "red", "black and red is red");
$c->add("blue");
is($c->colour, "magenta", "red and blue is magenta");
$c->add("green");
is($c->colour, "white", "magenta and green is white");

$c = Acme::Colour->new("black");
ok($c, "should get colour");
is("$c", "black", "should get black");
$c->add("green");
is($c->colour, "green", "black and green is green");
$c->add("blue");
is($c->colour, "cyan", "green and blue is cyan");
$c->add("red");
is($c->colour, "white", "cyan and red is white");

$c = Acme::Colour->new("black");
ok($c, "should get colour");
is("$c", "black", "should get black");
$c->add("green");
is($c->colour, "green", "black and green is green");
$c->add("red");
is($c->colour, "yellow", "green and red is yellow");
$c->add("blue");
is($c->colour, "white", "yellow and blue is white");

$c = Acme::Colour->new("yellow");
ok($c, "should get colour");
is($c->colour, "yellow", "should be yellow");
$c->add("green");
is($c->colour, "yellow", "yellow and green is yellow");
$c->add("red");
is($c->colour, "yellow", "yellow and red is yellow");
$c->add("yellow");
is($c->colour, "yellow", "yellow and yellow is yellow");


# Now test subtractive colour
ok(1, "Test subtractive colour");

$c = Acme::Colour->new("white");
ok($c, "should get colour");
$c->mix("black");
is("$c", "black", "should get black");
$c->mix("black");
is("$c", "black", "black and black is black");

$c = Acme::Colour->new("white");
ok($c, "should get colour");
is("$c", "white", "should get white");
$c->mix("cyan");
is("$c", "cyan", "white and cyan is cyan");
$c->mix("magenta");
is("$c", "blue", "cyan and magenta is blue");
$c->mix("yellow");
is("$c", "black", "blue and yellow is black");

$c = Acme::Colour->new("white");
ok($c, "should get colour");
is("$c", "white", "should get white");
$c->mix("yellow");
is("$c", "yellow", "white and yellow is yellow");
$c->mix("cyan");
is("$c", "green", "yellow and cyan is green");
$c->mix("magenta");
is("$c", "black", "green and magenta is black");

$c = Acme::Colour->new("white");
ok($c, "should get colour");
is("$c", "white", "should get white");
$c->mix("magenta");
is("$c", "magenta", "white and magenta is magenta");
$c->mix("yellow");
is("$c", "red", "magenta and yellow is red");
$c->mix("cyan");
is("$c", "black", "red and cyan is black");

ok(1, "Extra tests");
$c = Acme::Colour->new("orange");
ok($c, "should get colour");
is("$c", "orange", "should get orange");
$c->mix("brown");
like("$c", qr/dark ?red/, "orange and brown is dark red");

$c = Acme::Colour->new("white");
ok($c, "should get colour");
is("$c", "white", "should get white");
$c->mix("red");
is("$c", "red", "white and red is red");
$c->mix("blue");
is("$c", "black", "red and blue is black");

$c = Acme::Colour->new("white");
ok($c, "should get colour");
is("$c", "white", "should get white");
$c->mix("red", 0.5);
is("$c", "salmon", "white and half red is salmon");
$c->mix("cyan", 0.5);
like("$c", qr/dim ?gray/, "salman and half cyan is dim gray");

ok(1, "Colour constants");
use Acme::Colour constants => 1;

my $red = "red";
my $green = "green";
my $yellow = $red + $green;
is($yellow->colour, "yellow"->colour, "red and green make yellow");

my $cyan = "cyan";
my $magenta = "magenta";
my $blue = $cyan - $magenta;
is($blue->colour, "blue"->colour, "cyan and magenta make blue");

# Now let's test the errors

throws_ok {$c = Acme::Colour->new("bogus1")} qr/Colour bogus1 is unknown/;

# We have to monkey about on the insides to test this
$c->{colour} = "bogus2";
throws_ok {$c->add("bogus3")} qr/Colour bogus2 is unknown/;
$c->{colour} = "red";

throws_ok {$c->add("bogus4")} qr/Colour bogus4 is unknown/;

# We have to monkey about on the insides to test this
$c->{colour} = "bogus5";
throws_ok {$c->mix("bogus6")} qr/Colour bogus5 is unknown/;
$c->{colour} = "red";

throws_ok {$c->mix("bogus7")} qr/Colour bogus7 is unknown/;
