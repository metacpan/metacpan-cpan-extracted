#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 1;
use Address::PostCode::Australia::Place;

ok(Address::PostCode::Australia::Place->new);
