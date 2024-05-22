#!perl
use strict;
use warnings;
use lib 'lib', 't/lib';

use Feature::Compat::Defer;
use Path::Tiny 0.119;
use Test::More;
use TestArchiveSCS;

my $tempdir = Path::Tiny->tempdir('Archive-SCS-test-XXXXXX');
defer { $tempdir->remove_tree; }

# Mount multiple archive files

my $sample1 = $tempdir->child('sample1.scs');
create_hashfs1 $sample1, sample1;

my $sample2 = $tempdir->child('sample2.scs');
create_hashfs2 $sample2, sample2;

like scs_archive(-m => $sample2, -m => $sample1, -o => '-', -x => 'orphan'),
  qr{whats my name}, 'union';

# Extract multiple files at once

is scs_archive(-m => $sample1, -o => $tempdir, -x => 'orphan', 'empty'),
  '', 'extract ok';

ok $tempdir->child('orphan')->exists, 'extracted orphan';
ok $tempdir->child('empty' )->exists, 'extracted empty';

done_testing;
