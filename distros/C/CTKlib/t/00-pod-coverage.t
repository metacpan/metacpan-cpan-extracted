#!/usr/bin/perl -w
#########################################################################
#
# Serz Minus (Sergey Lepenkov), <abalama@cpan.org>
#
# Copyright (C) 1998-2019 D&D Corporation. All Rights Reserved
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: 00-pod-coverage.t 141 2017-01-21 12:22:25Z minus $
#
#########################################################################
use strict;
use Test::More;

# Ensure a recent version of Test::Pod::Coverage
my $ver = 1.08;
eval "use Test::Pod::Coverage $ver";
plan skip_all => "Test::Pod::Coverage $ver required for testing POD coverage" if $@;

# Test::Pod::Coverage doesn't require a minimum Pod::Coverage version,
# but older versions don't recognize some common documentation styles
my $verpc = 0.18;
eval "use Pod::Coverage $verpc";
plan skip_all => "Pod::Coverage $verpc required for testing POD coverage" if $@;
plan skip_all => "Currently a developer-only test" unless -d '.svn' || -d ".git";

# Modules white list
my @trust = qw(

);

# Functions white list
my %skip = (
    trustme => [
        qr/^[A-Z_0-9]+$/,
    ],
);

my @modules;
foreach my $l (all_modules()) {
    push @modules, $l unless grep {$l eq $_} @trust;
}

if ( @modules ) {
    plan tests => scalar @modules;
    for my $module ( @modules ) {
        my $thismsg = "Pod coverage on $module";
        pod_coverage_ok( $module, \%skip, $thismsg );
    }
} else {
    plan tests => 1;
    ok( 1, "No modules found." );
}

1;

__END__
