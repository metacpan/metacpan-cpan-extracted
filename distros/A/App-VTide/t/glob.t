#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Test::Warnings;
use App::VTide;

my $module = 'App::VTide::Command::Run';
use_ok( $module );

globable();

done_testing();

sub globable {
    my $run = App::VTide::Command::Run->new(
        vtide      => App::VTide->new,
        glob_depth => 3,
    );
    my @globs = $run->_globable('a/b');
    is $globs[0], 'a/b', 'Plain file just gets returned';

    @globs = $run->_globable('a/b*');
    is $globs[0], 'a/b*', 'Plain glob just gets returned';

    @globs = $run->_globable('a/**/b');
    is_deeply \@globs, [qw{a/b a/*/b a/*/*/b a/*/*/*/b}], 'simple ** is expanded'
        or diag explain \@globs;

    @globs = $run->_globable('a/**/b/**/c');
    is_deeply \@globs, [qw{
        a/b/c a/b/*/c a/b/*/*/c a/b/*/*/*/c
        a/*/b/c a/*/b/*/c a/*/b/*/*/c a/*/b/*/*/*/c
        a/*/*/b/c a/*/*/b/*/c a/*/*/b/*/*/c a/*/*/b/*/*/*/c
        a/*/*/*/b/c a/*/*/*/b/*/c a/*/*/*/b/*/*/c a/*/*/*/b/*/*/*/c
    }], 'deep ** is expanded'
        or diag explain \@globs;

    $run->glob_depth(2);
    @globs = $run->_globable('a/**/b');
    is_deeply \@globs, [qw{a/b a/*/b a/*/*/b}], 'simple ** is expanded with depth 2'
        or diag explain \@globs;
}
