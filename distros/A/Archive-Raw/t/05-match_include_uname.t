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

my $entry = $reader->next();
$entry = $reader->next();

$match->include_uname ('root');
is $entry->pathname, 'dir/file2.txt';
ok ($match->excluded ($entry));
ok ($match->owner_excluded ($entry));

$entry = $reader->next();
$entry = $reader->next();

$match->include_uname ('jacquesg');
is $entry->pathname, 'dir/file1.txt';
ok (!$match->excluded ($entry));
ok (!$match->owner_excluded ($entry));

done_testing;

