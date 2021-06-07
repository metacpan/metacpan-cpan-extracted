use strict;
use warnings;
use 5.020;
use Archive::Libarchive qw( :const );

my $tarball = 'archive.tar';

my $r = Archive::Libarchive::ArchiveRead->new;
$r->support_format_all;
$r->support_filter_all;

my $dw = Archive::Libarchive::DiskWrite->new;
$dw->disk_set_options(
  ARCHIVE_EXTRACT_TIME | ARCHIVE_EXTRACT_PERM | ARCHIVE_EXTRACT_ACL | ARCHIVE_EXTRACT_FFLAGS
);
$dw->disk_set_standard_lookup;

$r->open_filename($tarball) == ARCHIVE_OK
  or die "unable to open $tarball @{[ $r->error_string ]}";

my $e = Archive::Libarchive::Entry->new;
while(1) {
  my $ret = $r->next_header($e);
  last if $ret == ARCHIVE_EOF;
  if($ret < ARCHIVE_OK) {
    if($ret < ARCHIVE_WARN) {
      die "header read error on $tarball @{[ $r->error_string ]}";
    } else {
      warn "header read warning on $tarball @{[ $r->error_string ]}";
    }
  }

  $ret = $dw->write_header($e);
  if($ret < ARCHIVE_OK) {
    if($ret < ARCHIVE_WARN) {
      die "header write error on disk @{[ $dw->error_string ]}";
    } else {
      warn "header write warning disk @{[ $dw->error_string ]}";
    }
  }

  if($e->size > 0)
  {
    my $buffer;
    my $offset;
    while(1) {

      $ret = $r->read_data_block(\$buffer, \$offset);
      last if $ret == ARCHIVE_EOF;
      if($ret < ARCHIVE_OK) {
        if($ret < ARCHIVE_WARN) {
          die "file read error on member @{[ $e->pathname ]} @{[ $r->error_string ]}";
        } else {
          warn "file read warning on member @{[ $e->pathname ]} @{[ $r->error_string ]}";
        }
      }

      $ret = $dw->write_data_block(\$buffer, $offset);
      if($ret < ARCHIVE_OK) {
        if($ret < ARCHIVE_WARN) {
          die "file write error on member @{[ $e->pathname ]} @{[ $dw->error_string ]}";
        } else {
          warn "file write warning on member @{[ $e->pathname ]} @{[ $dw->error_string ]}";
        }
      }
    }
  }

  $dw->finish_entry;
  if($ret < ARCHIVE_OK) {
    if($ret < ARCHIVE_WARN) {
      die "finish error on disk @{[ $dw->error_string ]}";
    } else {
      warn "finish warning disk @{[ $dw->error_string ]}";
    }
  }
}

$r->close;
$dw->close;
