#!perl

use strict; use warnings;
use Data::Password::Filter;
use Test::More tests => 2;

my $password = Data::Password::Filter->new();

eval { $password->strength() };
like($@, qr/Missing password/);

is($password->strength('Ab12345?'), 'Very good');