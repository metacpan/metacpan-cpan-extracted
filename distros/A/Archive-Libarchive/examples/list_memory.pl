use strict;
use warnings;
use 5.020;
use Path::Tiny qw( path );
use Archive::Libarchive qw( ARCHIVE_OK );

my $r = Archive::Libarchive::ArchiveRead->new;
$r->support_filter_all;
$r->support_format_all;

my $buffer = path('archive.tar')->slurp_raw;

my $ret = $r->open_memory(\$buffer);
if($ret != ARCHIVE_OK) {
  exit 1;
}

my $e = Archive::Libarchive::Entry->new;
while($r->next_header($e) == ARCHIVE_OK) {
  say $e->pathname;
  $r->read_data_skip;
}
