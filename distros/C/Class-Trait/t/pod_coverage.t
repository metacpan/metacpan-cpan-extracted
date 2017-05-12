#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

local $SIG{__WARN__} = sub {
    my $message = shift;
    return if $message =~ /Too late to run INIT block/;
    warn $message;
};

eval "use Test::Pod::Coverage";
plan skip_all => "Test::Pod::Coverage required for testing POD coverage" if $@;

# dont bother testing Class::Trait itself as none of the methods are really
# public and all interaction is done through the 'import' interface anyway.

plan tests => 6;

pod_coverage_ok('Class::Trait::Config');
pod_coverage_ok('Class::Trait::Base');
pod_coverage_ok('Class::Trait::Reflection');
pod_coverage_ok('Class::Trait::Lib::TEquality');
pod_coverage_ok('Class::Trait::Lib::TPrintable');
pod_coverage_ok('Class::Trait::Lib::TComparable');
