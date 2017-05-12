#!/usr/bin/env perl
use strict;
use warnings;
use Crypt::Random::Seed;

use Test::More  tests => 4;

my $bsource = Crypt::Random::Seed->new();
my $bname = $bsource->name();
ok(defined($bname));
ok($bname ne '');

my $nbsource = Crypt::Random::Seed->new(NonBlocking=>1);
my $nbname = $nbsource->name();
ok(defined($nbname));
ok($nbname ne '');

diag "\nDefault     blocking method: $bname\nDefault non-blocking method: $nbname";
