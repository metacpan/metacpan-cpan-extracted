#!/usr/bin/env perl
use strict;
use warnings;

## random_octet.t
##
## Copyright (c) 2000, Vipul Ved Prakash.  All rights reserved.
## This code is free software; you can redistribute it and/or modify
## it under the same terms as Perl itself.

use Test::More;
use Crypt::RSA;
use Math::Prime::Util qw/random_bytes/;

plan tests => 3;

for my $len (qw/10 512 1024/) {
    my $ro = random_bytes($len);
    is(length($ro), $len, "random_bytes($len) creates $len bytes");
}
