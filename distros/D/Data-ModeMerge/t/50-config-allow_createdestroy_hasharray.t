#!perl

use strict;
use warnings;
use Test::More tests => 36;

use lib './t';
do 'testlib.pm';

use Data::ModeMerge;

for ([undef => undef], [scalar => 1], [hash => {}]) {
    mmerge_ok  ($_->[1], [], undef                  , "allow_create_array=1 ($_->[0])");
    mmerge_fail($_->[1], [], {allow_create_array=>0}, "allow_create_array=0 ($_->[0])");
}
mmerge_ok([], [], undef                  , 'allow_create_array=1 (array)');
mmerge_ok([], [], {allow_create_array=>0}, 'allow_create_array=0 (array)');

for ([undef => undef], [scalar => 1], [hash => {}]) {
    mmerge_ok  ([], $_->[1], undef                   , "allow_destroy_array=1 ($_->[0])");
    mmerge_fail([], $_->[1], {allow_destroy_array=>0}, "allow_destroy_array=0 ($_->[0])");
}
mmerge_ok([], [], undef                   , 'allow_destroy_array=1 (array)');
mmerge_ok([], [], {allow_destroy_array=>0}, 'allow_destroy_array=0 (array)');

for ([undef => undef], [scalar => 1], [array => []]) {
    mmerge_ok  ($_->[1], {}, undef                 , "allow_create_hash=1 ($_->[0])");
    mmerge_fail($_->[1], {}, {allow_create_hash=>0}, "allow_create_hash=0 ($_->[0])");
}
mmerge_ok({}, {}, undef                 , 'allow_create_hash=1 (hash)');
mmerge_ok({}, {}, {allow_create_hash=>0}, 'allow_create_hash=0 (hash)');

for ([undef => undef], [scalar => 1], [array => []]) {
    mmerge_ok  ({}, $_->[1], undef                 , "allow_destroy_hash=1 ($_->[0])");
    mmerge_fail({}, $_->[1], {allow_destroy_hash=>0}, "allow_destroy_hash=0 ($_->[0])");
}
mmerge_ok({}, {}, undef                  , 'allow_destroy_hash=1 (hash)');
mmerge_ok({}, {}, {allow_destroy_hash=>0}, 'allow_destroy_hash=0 (hash)');

# array & hash can also be destroyed by DELETE, e.g. {a=>{}} merge {"!a"=>{}}

mmerge_ok  ({a=>[]}, {"!a"=>[]}, undef                   , 'allow_destroy_array=1 (DELETE mode)');
mmerge_fail({a=>[]}, {"!a"=>[]}, {allow_destroy_array=>0}, 'allow_destroy_array=0 (DELETE mode)');

mmerge_ok  ({a=>{}}, {"!a"=>{}}, undef                  , 'allow_destroy_hash=1 (DELETE mode)');
mmerge_fail({a=>{}}, {"!a"=>{}}, {allow_destroy_hash=>0}, 'allow_destroy_hash=0 (DELETE mode)');
