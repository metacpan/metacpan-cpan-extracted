#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 1;
use Address::PostCode::UK::Place;

ok(Address::PostCode::UK::Place->new);
