#!/usr/bin/perl -w
#########################################################################
#
# Serż Minus (Sergey Lepenkov), <abalama@cpan.org>
#
# Copyright (C) 1998-2024 D&D Corporation. All Rights Reserved
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#########################################################################
use strict;
use warnings;
use Test::More tests => 3;

use Acrux::Digest::M11R;

my $m11r = Acrux::Digest::M11R->new();
#$empty->addfile("t.txt");

#print ">", $m11r->digest, "<\n";
is($m11r->data("123456789")->digest, 5, "M11R Check Digit for 123456789 is 5");
is($m11r->data("0")->digest, 0, "M11R Check Digit for 0 is 0");
is($m11r->data("987654321")->digest, 0, "M11R Check Digit for 987654321 is 0");

1;

__END__
