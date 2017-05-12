#!perl

use Test::Simple tests => 2;

use Data::Dimensions qw(&units extended);

my $kilojoule = units({'kilo-joule' => 1});
my $joule     = units({ joule => 1});

$joule->set = 1000;
$kilojoule->set = 1;

ok($joule == $kilojoule, "comparing after prefix");

$joule->set = 1;
$kilojoule->set = 1000 * $joule;

ok($kilojoule == 1, "expressions play nicely");
