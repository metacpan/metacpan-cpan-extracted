#!perl

use strict;
use warnings;
use Test::More;
use Archive::Raw;

my $reader = Archive::Raw::Reader->new();
isa_ok $reader, 'Archive::Raw::Reader';

$reader->open_filename ('test_archive.tar.gz');

my $match = Archive::Raw::Match->new;
isa_ok $match, 'Archive::Raw::Match';
$match->include_pattern_from_file ('t/include_path.txt');

my $entry = $reader->next();

$entry = $reader->next();
is $entry->pathname, 'dir/file2.txt';
ok ($match->excluded ($entry));

$entry = $reader->next();
$entry = $reader->next();

is $entry->pathname, 'dir/file1.txt';
ok (!$match->excluded ($entry));

done_testing;

