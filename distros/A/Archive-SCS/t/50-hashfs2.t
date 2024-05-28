#!perl
use strict;
use warnings;
use lib 'lib', 't/lib';
use Feature::Compat::Defer;

use Path::Tiny 0.119;
use Test::More;

my $file = Path::Tiny->tempfile('Archive-SCS-test-XXXXXX');
defer { $file->remove; }

use Archive::SCS;
use TestArchiveSCS;

# Minimal HashFS version 2 roundtrip test

create_hashfs2 $file, sample1;

my $scs = Archive::SCS->new;
$scs->mount($file);

is_deeply [$scs->list_dirs], [qw(
  dir
  dir/subdir
  emptydir
)], 'dirs';

is $scs->read_entry('ones'), '1' x 100, 'ones';

done_testing;
