#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use Path::Class qw( file );

BEGIN{ use_ok('Config::Locale') }

my $config_dir = file( $0 )->dir->subdir('permute');

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

    is_deeply( $config, $expected, join(', ', @$identity) );
}

done_testing;
