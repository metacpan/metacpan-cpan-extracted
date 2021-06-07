use strict;
use warnings;
use 5.020;
use Archive::Libarchive;

my $r = Archive::Libarchive::ArchiveRead->new;
$r->support_filter_all;
$r->support_format_raw;
$r->open_filename("hello.txt.uu");
$r->next_header(Archive::Libarchive::Entry->new);

my $buffer;
while($r->read_data(\$buffer)) {
  print $buffer;
}

$r->close;
