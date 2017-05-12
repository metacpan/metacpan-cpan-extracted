################################################################################
#
# Copyright (c) 2002-2015 Marcus Holland-Moritz. All rights reserved.
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
################################################################################

use Test::More tests => 2;
use Convert::Binary::C @ARGV;
use strict;

$^W = 1;

my $c = new Convert::Binary::C;

eval { $c->parse_file('tests/parser/context.c') };

is($@, '', 'parse context.c');

eval { $c->parse_file('tests/parser/bug1.c') };

like($@, qr/syntax error/, 'parse bug1.c');
