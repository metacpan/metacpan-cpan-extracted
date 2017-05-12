#!/usr/bin/env perl
#
# Copyright (C) 2017 by Tomasz Konojacki
#
# This library is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself, either Perl version 5.24.0 or,
# at your option, any later version of Perl 5 you may have available.
#
use strict;
use warnings;

use Test::More;
use Bytes::Random::XS qw/random_bytes/;

is random_bytes(-1), '', 'return "" for n <= 0 (1)';
is random_bytes(0), '', 'return "" for n <= 0 (1)';

for (1..64) {
    is length(random_bytes($_)), $_, "length(random_bytes(n)) == n ($_)"
}

done_testing;
