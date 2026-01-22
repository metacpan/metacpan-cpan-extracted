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
use Test::More tests => 4;

use Acrux::Digest::FNV32a;

my $fnv32a = Acrux::Digest::FNV32a->new();

$fnv32a->add("123456789");
is($fnv32a->digest, 0xbb86b11c, "FNV32a for 123456789 is 3146166556");
is($fnv32a->hexdigest, 'bb86b11c', "FNV32a (hex) for 123456789 is 0xbb86b11c");

$fnv32a->reset->add("abc123");
is($fnv32a->digest, 951228933, "FNV32a for abc123 is 951228933");

$fnv32a->reset->add("http://www.google.com/");
is($fnv32a->digest, 912201313, "FNV32a for http://www.google.com/ is 912201313");

1;

__END__
