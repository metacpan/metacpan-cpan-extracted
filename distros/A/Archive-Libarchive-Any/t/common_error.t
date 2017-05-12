use strict;
use warnings;
use Test::More tests => 6;
use Archive::Libarchive::Any qw( :all );

my $r;

my $archive = archive_read_new();
ok $archive, 'archive_read_new';

is archive_error_string($archive), undef, 'archive_error_string = undef';

$r = eval { archive_set_error($archive, 42, "error %d (%s)", 42, "KIRK") };
diag $@ if $@;
is $r, ARCHIVE_OK, 'archive_set_error';

like archive_error_string($archive), qr{error 42 \(KIRK\)}, 'archive_error_string = string';
is archive_errno($archive), 42, 'archive_errno = 42';

$r = archive_read_free($archive);
is $r, ARCHIVE_OK, 'archive_read_free';
