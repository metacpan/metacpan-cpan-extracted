#!perl -w
use strict;

package Sputz;
use Class::Std;

package Gishklork;
use Acme::Class::Std;

package main;

use Storable 'freeze';

use Test::More tests => 6;

my $normal = Sputz->new;
ok($normal, "Got something");
ok($normal->isa("SCALAR"), "But it's a scalar reference");
my $frozen = eval {freeze($normal)};
is ($@, '', "Can freeze it");

my $acmified = Gishklork->new;
ok($acmified, "Got something");
ok($acmified->isa("IO"), "It's an IO reference");
$frozen = eval {freeze($acmified)};
like ($@, qr/Can't store/, "Can't freeze Acme::Class::Std objects");




