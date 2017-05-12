#!perl

use strict;
use warnings;

use App::Genpass;
use Test::More tests => 5;

my $app    = App::Genpass->new( minlength => 7, maxlength => 10 );
my $pass;
my %seen;

for (my $i=0; $i<1000; $i++) {
    $pass = $app->generate();
    $seen{ length($pass) } = 1;
}
ok(int(keys %seen) == 4 && $seen{7} && $seen{8} && $seen{9} && $seen{10},
   "minlength=7 maxlength=10");

%seen = ();
$app = App::Genpass->new(minlength => 10, maxlength => 7);
for (my $i=0; $i<1000; $i++) {
    $pass = $app->generate();
    $seen{ length($pass) } = 1;
}
ok(int(keys %seen) == 4 && $seen{7} && $seen{8} && $seen{9} && $seen{10},
   "reversed minlength and maxlength");

%seen = ();
$app = App::Genpass->new(minlength => 8, maxlength => 8);
for (my $i=0; $i<1000; $i++) {
    $pass = $app->generate();
    $seen{ length($pass) } = 1;
}
ok(int(keys %seen) == 1 && $seen{8}, "min=8, max=8: should only see passwords of length 8");

%seen = ();
$app = App::Genpass->new(length => 8);
for (my $i=0; $i<1000; $i++) {
    $pass = $app->generate();
    $seen{ length($pass) } = 1;
}
ok(int(keys %seen) == 1 && $seen{8}, "only seen passwords of length 8");

%seen = ();
$app = App::Genpass->new();

for (my $i=0; $i<1000; $i++) {
    $pass = $app->generate();
    $seen{ length($pass) } = 1;
}
ok(int(keys %seen) == 3 && $seen{8} && $seen{9} && $seen{10},
   "default should be lengths >= 8 and <= 10");

