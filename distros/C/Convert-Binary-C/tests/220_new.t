################################################################################
#
# Copyright (c) 2002-2020 Marcus Holland-Moritz. All rights reserved.
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
################################################################################

use Test;
use Convert::Binary::C @ARGV;

$^W = 1;

BEGIN {
  plan tests => 3;
}

# This test is basically only for the 901_memory.t test

$c = eval { Convert::Binary::C->new };
ok( $@, '' );

$c = eval { Convert::Binary::C->new( 'foo' ) };
ok( $@, qr/^Number of configuration arguments to new must be even/ );

$c = eval { Convert::Binary::C->new( foo => 42 ) };
ok( $@, qr/^Invalid option 'foo'/ );
