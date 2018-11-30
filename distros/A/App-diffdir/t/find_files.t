#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Test::Warnings;
use Path::Tiny;
use lib qw{t/lib};
use DirBuilder qw{build_tree};;

my $module = 'App::diffdir';
use_ok( $module );

find_files_default();
find_files_excluded();

done_testing();

sub find_files_default {
    my $dd = App::diffdir->new;

    my $path = {
        '.git' => {
        },
        file1 => 1,
        file2 => 2,
        dir1  => {
            dfile1 => 3,
        }
    };
    build_tree( 't/find_files/a', $path );
    my @a = $dd->find_files('t/find_files/a');
    is scalar @a, 4, 'Find all 4 files';
    ok !(grep {/[.]git/} @a), "Default excluded directory isn't found";

    # clean up
    path('t/find_files')->remove_tree;
}

sub find_files_excluded {
    my $dd = App::diffdir->new(
        exclude => [qw/file2/],
    );;

    my $path = {
        '.git' => {
        },
        file1 => 1,
        file2 => 2,
        dir1  => {
            dfile1 => 3,
        }
    };
    build_tree( 't/find_files/a', $path );
    my @a = $dd->find_files('t/find_files/a');
    is scalar @a, 3, 'Find only 4 files';
    ok !(grep {/file2/} @a), "Excluded 'file2' from list found";

    # clean up
    path('t/find_files')->remove_tree;
}
