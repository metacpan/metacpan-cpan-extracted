#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use App::FileRemoveUtils qw(delete_all_empty_files delete_all_empty_dirs);
use File::chdir;
use File::Slurper qw(write_text);
use File::Temp qw(tempdir);

my $tempdir = tempdir(CLEANUP=>1);

subtest delete_all_empty_files => sub {
    local $CWD = $tempdir;
    mkdir "sub1", 0755;
    write_text("e1", "");
    write_text("e2", "");
    write_text("sub1/e1", "");
    write_text("sub1/ne1", "a");
    write_text("ne1", "a");
    write_text("ne2", "b");

    delete_all_empty_files(-dry_run=>1);
    is_deeply([sort glob("*")], [qw(e1 e2 ne1 ne2 sub1)]);
    is_deeply([sort glob("sub1/*")], [qw(sub1/e1 sub1/ne1)]);

    delete_all_empty_files();
    is_deeply([sort glob("*")], [qw(ne1 ne2 sub1)]);
    is_deeply([sort glob("sub1/*")], [qw(sub1/ne1)]);
};

subtest delete_all_empty_dirs => sub {
    local $CWD = $tempdir;
    mkdir "sub1", 0755;
    mkdir "sub1/sub2", 0755;
    mkdir "sub3", 0755;
    mkdir "sub3/sub4", 0755;
    mkdir "sub3/sub4/sub5", 0755;
    mkdir "sub3/sub6", 0755;
    write_text("e1", "");
    write_text("e2", "");
    write_text("sub1/e1", "");
    write_text("sub1/ne1", "a");
    write_text("ne1", "a");
    write_text("ne2", "b");

    delete_all_empty_dirs(-dry_run=>1);
    is_deeply([sort glob("*")], [qw(e1 e2 ne1 ne2 sub1 sub3)]);

    delete_all_empty_dirs();
    is_deeply([sort glob("*")], [qw(e1 e2 ne1 ne2 sub1)]);
    is_deeply([sort glob("sub1/*")], [qw(sub1/e1 sub1/ne1)]);
};

done_testing;
