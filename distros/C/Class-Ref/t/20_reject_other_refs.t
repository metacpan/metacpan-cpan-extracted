#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 16;

use Class::Ref;

my $error_test = qr/not a valid reference for Class::Ref/;

# for LVALUE test
my $str = 'foo';

# for FORMAT test
format =
.

my %tests = (
    SCALAR  => \1,
    CODE    => sub { },
    REF     => \\1,
    GLOB    => \*_,
    LVALUE  => \substr($str, 0, 1),
    FORMAT  => *STDOUT{FORMAT},       # >= 5.8.9
    Regexp  => qr//,                  # >= 5.8.9
    VSTRING => \v1.0,                 # >= 5.10.0
##  IO => *STDIN{IO}, # not really testable (>= 5.8.9)
);

while (my ($type, $ref) = each %tests) {
    eval { Class::Ref->new($ref) };
    like $@, $error_test, "reject $type";
}

my $obj = Class::Ref->new({});

while (my ($type, $ref) = each %tests) {
    SKIP: {
        skip "$type not available in perl < 5.8.9", 1
          if $type =~ /^(FORMAT|IO|Regexp)$/ and $] < 5.008009;

        skip "$type not available in perl < 5.10.0", 1
          if $type eq 'VSTRING' and $] < 5.010000;

        $obj->holder($ref);
        is ref $obj->holder, $type, " passthru $type";
    }
}
