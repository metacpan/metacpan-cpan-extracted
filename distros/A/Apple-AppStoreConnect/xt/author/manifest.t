#!perl
use strict;
use warnings;
use Test::More;
use ExtUtils::Manifest;

unless ( $ENV{RELEASE_TESTING} ) {
    plan( skip_all => "Author tests not required for installation" );
}

is_deeply [ ExtUtils::Manifest::manicheck() ], [], 'missing';
is_deeply [ ExtUtils::Manifest::filecheck() ], [], 'extra';

my $manifest = ExtUtils::Manifest::maniread();
my $skipchk  = ExtUtils::Manifest::maniskip();

ok(!$skipchk->($_), "$_ shouldn't be in MANIFEST.SKIP") for keys %$manifest;

done_testing;
