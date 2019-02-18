#!/usr/bin/env perl
use strict;
use warnings;
use Test2::V0;

use Path::Tiny;

use Config::Locale;

my $config_dir = path( $0 )->sibling('permute');

my @test_cases = (
    [ [qw( foo )]     => { iam => { foo=>1 } } ],
    [ [qw( foo bar )] => { iam => { foo=>1, bar=>1, 'foo.bar'=>1 } } ],
    [ [qw( bar )]     => { iam => { bar=>1 } } ],
);

foreach my $case (@test_cases) {
    my ($identity, $expected) = @$case;

    my $config = Config::Locale->new(
        directory => $config_dir,
        identity  => $identity,
        algorithm => 'PERMUTE',
    )->config();

    is( $config, $expected, join(', ', @$identity) );
}

done_testing;
