#!/usr/bin/perl

BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for release candidate testing');
  }
}


use strict;
use warnings;

use Test::More;

eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage"
    if $@;

eval "use Pod::Coverage::Moose 0.02";
plan skip_all => "Pod::Coverage::Moose 0.02 required for testing POD coverage"
    if $@;

my %skip = map { $_ => 1 } qw(
    Antispam::Toolkit::Conflicts
    Antispam::Toolkit::Types::Internal
);

my @modules = grep { ! $skip{$_} } all_modules();
plan tests => scalar @modules;

my %trustme;

for my $module ( sort @modules ) {
    my $trustme = [];

    if ( $trustme{$module} ) {
        my $methods = join '|', @{ $trustme{$module} };
        $trustme = [qr/^(?:$methods)$/];
    }

    pod_coverage_ok(
        $module, {
            coverage_class => 'Pod::Coverage::Moose',
            trustme        => $trustme,
        },
        "Pod coverage for $module"
    );
}
