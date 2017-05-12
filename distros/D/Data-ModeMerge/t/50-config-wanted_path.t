#!perl

use strict;
use warnings;
use Test::More tests => 2;

use lib './t';
do 'testlib.pm';

use Data::ModeMerge;

my $h1 = {i=>1, h=>{i=>1, h=>{i=>1, j=>1}, h2=>{i=>1, j=>1}}, h2=>{i=>1}};
my $h2 = {i=>2, h=>{i=>2, h=>{i=>2}, h2=>{i=>2}}, h2=>{i=>2}};
mmerge_is($h1, $h2, undef                     , {i=>2, h=>{i=>2, h=>{i=>2, j=>1}, h2=>{i=>2, j=>1}}, h2=>{i=>2}}, "wanted_path 1");
mmerge_is($h1, $h2, {wanted_path=>["h", "h2"]}, {i=>2, h=>{i=>2, h2=>{i=>2, j=>1}}}                             , "wanted_path 2");
