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

my @in = map { "$_\n" } qw( ones dir/subdir/SubDirFile );
my ($out, $err);

chdir path(__FILE__)->parent->parent;
run3 [
  qw( perl -Ilib script/scs_archive -x - -o - ),
  -m => $sample1,
], \@in, \$out, \$err;

is $err, '', 'no error';
like $out, qr{11111}, 'ones';
like $out, qr{in a subdirectory}, 'subdir file';

done_testing;
