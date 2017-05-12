#!perl

use strict; use warnings;
use Data::Password::Filter;
use Test::More tests => 3;

my $password = Data::Password::Filter->new();

eval { $password->score() };
like($@, qr/Missing password/);

is($password->score('Ab12345?'), '100%');

$password = Data::Password::Filter->new();
$password->strength('Ab12345?');
is($password->score(), '100%');