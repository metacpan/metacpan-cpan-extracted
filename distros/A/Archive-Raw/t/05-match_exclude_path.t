#!perl

use strict;
use warnings;
use Test::More;
use Archive::Raw;

my $reader = Archive::Raw::Reader->new();
isa_ok $reader, 'Archive::Raw::Reader';

$reader->open_filename ('test_archive.tar.gz');

my $entry = $reader->next();
$entry = $reader->next();
is $entry->pathname, 'dir/file2.txt';

my $match = Archive::Raw::Match->new;
isa_ok $match, 'Archive::Raw::Match';

ok (!$match->excluded ($entry));
$match->exclude_pattern ('dir');
ok ($match->excluded ($entry));
ok ($match->path_excluded ($entry));
ok (!$match->time_excluded ($entry));
ok (!$match->owner_excluded ($entry));

$match = Archive::Raw::Match->new;
$match->exclude_pattern ('file2.*');
ok ($match->excluded ($entry));
ok ($match->path_excluded ($entry));
ok (!$match->time_excluded ($entry));
ok (!$match->owner_excluded ($entry));

$entry = $reader->next();

$entry = $reader->next();
is $entry->pathname, 'dir/file1.txt';
ok (!$match->excluded ($entry));

$match->exclude_pattern ('*.txt');
ok ($match->excluded ($entry));
ok ($match->path_excluded ($entry));
ok (!$match->time_excluded ($entry));
ok (!$match->owner_excluded ($entry));

done_testing;

