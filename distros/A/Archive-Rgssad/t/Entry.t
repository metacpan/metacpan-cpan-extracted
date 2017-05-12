use strict;
use warnings;
use Archive::Rgssad::Entry;
use Test::More tests => 4;

my $entry = Archive::Rgssad::Entry->new('path', 'data');

is($entry->path, 'path', 'get path');
$entry->path('Data\Scripts.rxdata');
is($entry->path, 'Data\Scripts.rxdata', 'set path');

is($entry->data, 'data', 'get gata');
$entry->data('Hello, World!');
is($entry->data, 'Hello, World!', 'set data');

1;
