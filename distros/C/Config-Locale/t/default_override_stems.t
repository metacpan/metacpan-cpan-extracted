#!/usr/bin/env perl
use 5.008001;
use strict;
use warnings;
use Test2::V0;

use Path::Tiny;

use Config::Locale;

my @tests;

foreach my $type (qw( default override )) {

    my @test_cases = (
        [ undef, "/foo/bar/$type" ],
        [ 'test1', "/foo/bar/test1" ],
        [ '../test2', '/foo/bar/../test2' ],
        [ '/test3', '/test3' ],
    );

    foreach my $test (@test_cases) {
        my ($stem, $expected) = @$test;

        my $config = Config::Locale->new(
            directory    => '/foo/bar',
            identity     => [qw( red green )],
            ( defined($stem) ? ($type . '_stem' => $stem) : () ),
        );

        my $actual = ($type eq 'default')
                   ? $config->_default_stem_path()
                   : $config->_override_stem_path();

        $expected = path( $expected )->absolute( $config->_directory_path() );

        is(
            $actual . '',
            $expected . '',
            $type . ' stem resolved to ' . $expected,
        );
    }

}

done_testing;
