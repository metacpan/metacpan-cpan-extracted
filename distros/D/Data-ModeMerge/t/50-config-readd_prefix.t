#!perl

use strict;
use warnings;
use Test::More tests => 2;

use lib './t';
do 'testlib.pm';

use Data::ModeMerge;

mmerge_is({"^a"=>1}, {'a'=>2}, undef            , {"^a"=>1}, 'readd_prefix default');
mmerge_is({"^a"=>1}, {'a'=>2}, {readd_prefix=>0}, {  a =>1}, 'readd_prefix 0');
