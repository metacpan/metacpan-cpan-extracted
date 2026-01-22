#!/usr/bin/perl -w
#########################################################################
#
# Serż Minus (Sergey Lepenkov), <abalama@cpan.org>
#
# Copyright (C) 1998-2026 D&D Corporation
#
# This program is distributed under the terms of the Artistic License 2.0
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

my %skip = (
    trustme => [
        qr/^[A-Z_]+$/,
    ],
  );
all_pod_coverage_ok(\%skip);

1;

__END__
