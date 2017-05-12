use strict;
use warnings;

use Test::More;

eval "use DBD::SQLite";
plan skip_all => 'needs DBD::SQLite for testing' if $@;
plan tests => 5;

use lib 't/lib';

use_ok('SweetTest');

cmp_ok(SweetTest::CD->count({ 'artist.name' => 'Caterwauler McCrae' }),
           '==', 3, 'Count by has_a ok');

cmp_ok(SweetTest::CD->count({ 'tags.tag' => 'Blue' }),
           '==', 4, 'Count by has_many ok');

cmp_ok(SweetTest::CD->count(
           { 'liner_notes.notes' => { '!=' =>  undef } }),
           '==', 3, 'Count by might_have ok');

cmp_ok(SweetTest::CD->count(
           { 'year' => { '>', 1998 }, 'tags.tag' => 'Cheesy',
               'liner_notes.notes' => { 'like' => 'Buy%' } } ),
           '==', 2, "Mixed count ok");
