#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

use ok 'Crypt::Random::Source::Weak::OpenSSLRand';

my $p = Crypt::Random::Source::Weak::OpenSSLRand->new;

my $buf = $p->get(1024);

is( length($buf), 1024, "got 1kb" );


