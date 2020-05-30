#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use App::FileRenameUtils qw(add_filename_suffix find_unique_filename);
use File::Slurper qw(write_text);
use File::Temp qw(tempdir);

my $tempdir = tempdir(CLEANUP=>1);
write_text("$tempdir/foo", "");
write_text("$tempdir/foo.jpg", "");
write_text("$tempdir/bar", "");
write_text("$tempdir/bar (1)", "");
write_text("$tempdir/bar (2)", "");

subtest add_filename_suffix => sub {
    is(add_filename_suffix("foo", " (1)"), "foo (1)");
    is(add_filename_suffix("foo.jpg", " (1)"), "foo (1).jpg");
};

subtest add_filename_suffix => sub {
    is(find_unique_filename("$tempdir/foo"), "$tempdir/foo (1)");
    is(find_unique_filename("$tempdir/foo.jpg"), "$tempdir/foo (1).jpg");
    is(find_unique_filename("$tempdir/bar"), "$tempdir/bar (3)");
    is(find_unique_filename("$tempdir/baz"), "$tempdir/baz");
};

done_testing;
