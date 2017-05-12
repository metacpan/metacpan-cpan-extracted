#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 2;
use File::Spec;
use Alien::V8;

my %SharedLibExt = (
    default => ".so",
    darwin => ".dylib"
);

ok(
    -f File::Spec->catfile(Alien::V8->incdir(), "v8.h"),
    "v8 include file"
);

my $libname = "libv8" . (
    exists($SharedLibExt{$^O})
    ? $SharedLibExt{$^O}
    : $SharedLibExt{default}
);

ok(
    -f File::Spec->catfile(Alien::V8->libdir(), $libname),
    "v8 library"
);
