#!perl -T
use strict qw(vars);
use warnings;
#use Data::Dumper;
use Test::More 'no_plan';

BEGIN {
    use_ok( 'Color::Model::Munsell', ":all" ) || print "Bail out!";
}

diag( "Testing Color::Model::Munsell $Color::Model::Munsell::VERSION, Perl $], $^X" );

my $red = Color::Model::Munsell->new("4.0R 3.5/11.0");
my $red_ = Munsell("4.0R 3.5/11.0");

ok("$red" eq "$red_",        "Munsell()     - red, $red");
ok("$red" eq "4R 3.5/11",    "stringify     - red, $red");
ok($red->ischromatic,        "ischromatic() - red, $red");
ok(!$red->isneutral,         "isneutral()   - red, $red");
ok($red->hue eq '4R',        "hue()         - red, $red");
ok($red->hueCol eq 'R',      "hueCol()      - red, $red");
ok($red->hueStep== 4.0,      "hueStep()     - red, $red");
ok($red->value == 3.5,       "value()       - red, $red");
ok($red->lightness == 3.5,   "lightness()   - red, $red");
ok($red->chroma == 11.0,     "chroma()      - red, $red");
ok($red->saturation == 11.0, "saturation()  - red, $red");
ok($red->code eq "4R 3.5/11","code()        - red, $red");
ok($red->degree == 4.0,      "degree()      - red, $red");
ok(!$red->iswhite,           "iswhite()     - red, $red");
ok(!$red->isblack,           "isblack()     - red, $red");

my $purple = Color::Model::Munsell->new("5.5P", 5.0, 10);
ok("$purple" eq "5.5P 5/10", "stringify     - purple, $purple");
ok($purple->degree == 85.5,    "degree()      - $purple");

my $col1 = Color::Model::Munsell->new("10Y", 5.0, 10);
ok("$col1" eq "10Y 5/10",     "check for hue border, $col1");

my $col2 = Color::Model::Munsell->new("0GY", 5.0, 10);
ok("$col2" eq "$col1",        "check for hue border, $col2");

my $col3 = Color::Model::Munsell->new("10RP", 5.0, 10);
ok($col3->degree == 0,        "check for hue border, $col3");

ok(degree("10RP") == $col3->degree, "function degree(\"10RP\")");
ok(degree("5.5P") == $purple->degree, "function degree(\"5.5P\")");
ok($col3->hue eq undegree($col3->degree), "function undegree(0)");
ok($purple->hue eq undegree($purple->degree), "function degree(85.5)");

my $pB = PUREBLACK;
my $rB = REALBLACK;
my $pW = PUREWHITE;
my $rW = REALWHITE;
ok($rW->iswhite,           "iswhite()     - about real white");
ok($rB->isblack,           "isblack()     - about real black");

my $gray = Color::Model::Munsell->new("N", 4.5);
ok($gray->code eq "N 4.5",   "code()        - $gray");
ok(!$gray->ischromatic,      "ischromatic() - $gray");
ok($gray->isneutral,         "is_gray()     - $gray");
ok($gray->hue eq 'N',        "hue()         - $gray");
ok($gray->value == 4.5,      "value()       - $gray");
ok($gray->code eq "N 4.5",   "code()        - $gray");

$gray = Color::Model::Munsell->new("4R 5/0");
ok($gray->code eq "N 5.0",   "make \"4R 5/0\" neutral");
$gray = Color::Model::Munsell->new("4R 0/1");
ok($gray->code eq "N 0.0",   "make \"4R 0/1\" neutral");
$gray = Color::Model::Munsell->new("4R 10/1");
ok($gray->code eq "N 10.0",   "make \"4R 10/1\" neutral");

