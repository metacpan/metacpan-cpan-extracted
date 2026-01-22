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
use warnings;
use Test::More;

use Acrux::Digest::Damm;

my $damm = Acrux::Digest::Damm->new();

is($damm->data("123456789")->checkdigit, 4, "Damm Check Digit for 123456789 is 4");
is($damm->data("1234567894")->checkdigit, 0, "Damm Check Digit for 1234567894 is 0 (check)");
is($damm->data("987654321")->checkdigit, 5, "Damm Check Digit for 987654321 is 5");
is($damm->data("9876543215")->checkdigit, 0, "Damm Check Digit for 9876543215 is 0 (check)");
is($damm->data("0")->checkdigit, 0, "Damm Check Digit for 0 is 0");
is($damm->data("")->checkdigit, 0, "Damm Check Digit for '' is 0");

eval { $damm->data("123abc")->checkdigit };
like($@, qr/Incorrect input digit-string/, "Croak on invalid input");

done_testing;

1;

__END__

prove -lv t/12-digest-damm.t
