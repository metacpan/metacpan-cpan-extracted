use strict;
use warnings;
use 5.020;
use Archive::Libarchive qw( :const );

my $r = Archive::Libarchive::ArchiveRead->new;
$r->support_filter_all;
$r->support_format_all;
$r->open_filename("archive.tar", 10240) == ARCHIVE_OK
  or die $r->error_string;

my $e = Archive::Libarchive::Entry->new;
say $e->pathname while $r->next_header($e) == ARCHIVE_OK;
