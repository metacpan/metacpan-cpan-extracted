#!/usr/bin/env perl
use strict;
use warnings;

## Copyright (c) 2000, Vipul Ved Prakash.  All rights reserved.
## This code is free software; you can redistribute it and/or modify
## it under the same terms as Perl itself.

use Test::More;
use Crypt::RSA::DataFormat qw(octet_xor);
use Data::Dumper;

plan tests => 2;

my $a = "abcdefghijklmnopqrstuvwxyz";
my $b = "ABCDEFGHIJ";
my $d = octet_xor ($a, $b);
my $e = octet_xor ($d, $b);
my $f = octet_xor ($d, $a);
$f =~ s/^\0+//;

is($e, $a, "(a xor b) xor b = a");

# if octet_xor has endianness issues, this should break.
is($f, $b, "(a xor b) xor a = b");
