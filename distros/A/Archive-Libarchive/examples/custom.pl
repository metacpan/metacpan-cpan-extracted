use strict;
use warnings;
use 5.020;
use Archive::Libarchive qw( :const );

my $r = Archive::Libarchive::ArchiveRead->new;
$r->support_filter_all;
$r->support_format_all;

my $fh;

$r->open(
  open => sub {
    open $fh, '<', 'archive.tar';
    binmode $fh;
    return ARCHIVE_OK;
  },
  read => sub {
    my(undef, $ref) = @_;
    my $size = read $fh, $$ref, 512;
    return $size;
  },
  close => sub {
    close $fh;
    return ARCHIVE_OK;
  },
) == ARCHIVE_OK or die $r->error_string;

my $e = Archive::Libarchive::Entry->new;
while(1) {
  my $ret = $r->next_header($e);
  last if $ret == ARCHIVE_EOF;
  die $r->error_string if $ret < ARCHIVE_WARN;
  warn $r->error_string if $ret != ARCHIVE_OK;
  say $e->pathname;
}

$r->close;
