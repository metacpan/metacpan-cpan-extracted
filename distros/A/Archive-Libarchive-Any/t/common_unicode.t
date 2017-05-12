use strict;
use warnings;
use utf8;
use open ':std', ':encoding(utf8)';
use Test::More;
use Archive::Libarchive::Any qw( :all );

plan skip_all => 'test requires unicode locale' unless archive_perl_utf8_mode();
plan tests => 2;

my $e = archive_entry_new();

my $r = archive_entry_set_pathname($e, "привет.txt");
is $r, ARCHIVE_OK, 'archive_entry_set_pathname';
is archive_entry_pathname($e), "привет.txt", 'archive_entry_pathname';
