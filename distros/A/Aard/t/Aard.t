#!/usr/bin/perl -w
use v5.14;
use strict;
use warnings;

use Test::More tests => 9;
BEGIN { use_ok('Aard') };

my $dict = Aard->new('t/jargon-4.4.7-1.aar');
is lc $dict->uuid_string, '4e5c4639-9d1d-42ee-b27d-b552d6b7386d', 'uuid_string';
is $dict->volume, 1, 'volume';
is $dict->total_volumes, 1, 'total_volumes';
is $dict->count, 2307, 'count';

is $dict->title, 'The Jargon File', 'title';
is $dict->index_language, 'ENG', 'index_language';

is $dict->key(20), 'admin', 'key 20';
like $dict->article(20), qr/administrator/, 'value 20';
