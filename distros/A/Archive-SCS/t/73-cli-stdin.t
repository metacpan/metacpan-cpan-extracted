#!perl
use strict;
use warnings;
use lib 'lib', 't/lib';
use blib;
use Feature::Compat::Defer;

use IPC::Run3;
use Path::Tiny 0.119;
use Test::More;
use TestArchiveSCS;

can_test_cli() or plan skip_all => 'Cannot test cli';

my $tempdir = Path::Tiny->tempdir('Archive-SCS-test-XXXXXX');
defer { $tempdir->remove_tree; }

# Supply files to be extracted on std input

my $sample1 = $tempdir->child('sample1.scs');
create_hashfs2 $sample1, sample1;

my $in = join "", map { "$_\n" } qw( ones dir/subdir/SubDirFile );

my @out = scs_archive(-x => '-', -o => '-', -m => $sample1, \$in);

like $out[0], qr{11111}, 'ones';
like $out[1], qr{in a subdirectory}, 'subdir file';
is scalar(@out), 2, 'no error';

done_testing;
