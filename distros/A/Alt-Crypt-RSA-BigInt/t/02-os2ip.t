#!/usr/bin/env perl
use strict;
use warnings;

## Copyright (c) 2000, Vipul Ved Prakash.  All rights reserved.
## This code is free software; you can redistribute it and/or modify
## it under the same terms as Perl itself.

use Test::More;
use Crypt::RSA::DataFormat qw(i2osp os2ip);
use Math::BigInt try => 'GMP, Pari';

plan tests => 6;

my $string = "abcdefghijklmnopqrstuvwxyz-0123456789-abcdefghijklmnopqrstuvwxyz-abcdefghijklmnopqrstuvwxyz-0123456789";
my $number = Math::BigInt->new("166236188672784693770242514753420034912412776787232632921068824014646347893937590064771712921923774969379936913356439094695954550320707099033382274920372913421785829711983357001510792400267452442816935867829132703234881800415259286201953001355321");

my $n = os2ip ($string);
is($n, $number, "os2ip(string)");
my $str = i2osp ($n);
is($str, $string, "i2osp(n)");
my $str2 = i2osp ($number);
is($str2, $string, "i2osp(number)");

$string = "abcd";
$number = 1_633_837_924;
$n = os2ip ($string);
is($n, $number, "os2ip(string)");
$str = i2osp ($n);
is($str, $string, "i2osp(n)");
$str2 = i2osp ($number);
is($str2, $string, "i2osp(number)");
