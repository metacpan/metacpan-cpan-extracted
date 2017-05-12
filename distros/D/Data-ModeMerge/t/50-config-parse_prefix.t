#!perl

use strict;
use warnings;
use Test::More tests => 2;

use lib './t';
do 'testlib.pm';

use Data::ModeMerge;

mmerge_is({a=>1}, {'*a'=>3}, undef            , {a=>3}         , 'parse_prefix default');
mmerge_is({a=>1}, {'*a'=>3}, {parse_prefix=>0}, {a=>1, '*a'=>3}, 'parse_prefix 0');
