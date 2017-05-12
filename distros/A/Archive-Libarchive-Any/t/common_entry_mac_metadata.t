use strict;
use warnings;
use Test::More;
use Archive::Libarchive::Any qw( :all );

plan skip_all => 'requires archive_entry_mac_metadata' unless Archive::Libarchive::Any->can('archive_entry_mac_metadata');
plan tests => 5;

my $r;
my $e = archive_entry_new();

is eval { archive_entry_mac_metadata($e) }, undef, 'archive_entry_mac_metadata';

$r = eval { archive_entry_set_mac_metadata($e, "foo\0bar") };
diag $@ if $@;
is $r, ARCHIVE_OK, 'archive_entry_set_mac_metadata';

is eval { archive_entry_mac_metadata($e) }, "foo\0bar", 'archive_entry_mac_metadata';

$r = eval { archive_entry_copy_mac_metadata($e, "baz\0bar") };
diag $@ if $@;
is $r, ARCHIVE_OK, 'archive_entry_copy_mac_metadata';

is eval { archive_entry_mac_metadata($e) }, "baz\0bar", 'archive_entry_mac_metadata';

archive_entry_free($e);
