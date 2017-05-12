#!/usr/bin/perl -w
#########################################################################
#
# Sergey Lepenkov (Serz Minus), <minus@mail333.com>
#
# Copyright (C) 1998-2017 D&D Corporation. All Rights Reserved
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

my $skip = {
    trustme => [
        qr/CP1251toUTF8/,
        qr/UTF8toCP1251/,
        qr/^[A-Z_0-9]+$/,
    ],
};

#all_pod_coverage_ok($skip);
my @classes = (qw/
	CTK CTKx CTK::CPX CTK::DBI CTK::Helper CTK::Util
	CTK::Arc CTK::Crypt CTK::File CTK::Net
	CTK::CLI CTK::Log CTK::Status
	CTK::ConfGenUtil CTK::TFVals
    /);
plan tests => scalar(@classes);
pod_coverage_ok( $_, $skip ) for @classes;

1;
__END__
