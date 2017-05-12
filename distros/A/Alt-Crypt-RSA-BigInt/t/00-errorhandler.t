#!/usr/bin/env perl
use strict;
use warnings;

## 00-errorhandler.t -- Test for the base class and error handling
##                      methods therein.
##
## Copyright (c) 2001, Vipul Ved Prakash.  All rights reserved.
## This code is free software; you can redistribute it and/or modify
## it under the same terms as Perl itself.

use Test::More;
use Crypt::RSA::Errorhandler;

plan tests => 6;

my $i = 0;
my $plaintext = "data";
my @plaintext = qw(1 3 4 5);
my %plaintext = qw(a 1 b 2);
my $rsa = new Crypt::RSA::Errorhandler;

$rsa->error ("Message too short", \$plaintext);
is($rsa->errstr, "Message too short\n", "Set error string with scalar");
is($plaintext, "", "\$plaintext is empty string");

$rsa->error ("Out of range", \@plaintext);
is($rsa->errstr, "Out of range\n", "Set error string with array");
is_deeply(\@plaintext, [], "\@plaintext is empty array");

$rsa->error ("Bad values", \%plaintext);
is($rsa->errstr, "Bad values\n", "Set error string with hash");
is_deeply(\%plaintext, {}, "\%plaintext is empty hash");

