use strict;
use warnings;
use Test::More tests => 3;
use Archive::Libarchive::Any qw( :all );

my $r;

my $a = archive_read_new();
ok $a, 'archive_read_new';

is archive_error_string($a), undef, 'archive_error_string';

$r = archive_read_free($a);
is $r, ARCHIVE_OK, 'archive_read_free';
