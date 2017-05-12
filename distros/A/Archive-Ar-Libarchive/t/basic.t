use strict;
use warnings;
use Test::More tests => 1;
use Archive::Ar::Libarchive;

my $ar = Archive::Ar::Libarchive->new;
isa_ok $ar, 'Archive::Ar::Libarchive';
