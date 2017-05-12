#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use Path::Class qw( file );

BEGIN{ use_ok('Config::Locale') }

my @tests;

foreach my $type (qw( default override )) {

    my @test_cases = (
        [ undef, "/foo/bar/$type" ],
        [ 'test1', "/foo/bar/test1" ],
        [ '../test2', '/foo/bar/../test2' ],
        [ '/test3', '/test3' ],
        [ file('test1'), '/foo/bar/test1' ],
        [ file('../test2'), '/foo/bar/../test2' ],
        [ file('/test3'), '/test3' ],
    );

    foreach my $test (@test_cases) {
        my ($stem, $expected) = @$test;

        my $config = Config::Locale->new(
            directory    => '/foo/bar',
            identity     => [qw( red green )],
            ( defined($stem) ? ($type . '_stem' => $stem) : () ),
        );

        my $actual = ($type eq 'default') ? $config->default_stem() : $config->override_stem();

        is(
            $actual . '',
            file($expected) . '',
            $type . ' stem resolved to ' . $expected,
        );
    }

}

done_testing;
