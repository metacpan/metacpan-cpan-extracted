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

BEGIN { plan tests => 6 }

eval {
  $c = Convert::Binary::C->new;
};
ok($@,'',"failed to create Convert::Binary::C object");

eval {
  $c->clean;
};
ok($@,'',"failed to clean object");

eval {
  $c->parse( 'typedef struct foo { enum bar { ZERO } baz; } mytype;' );
};
ok($@,'',"failed to parse code");

eval {
  $copy = $c->clean;
};
ok($@,'',"failed to clean object");
ok($copy, $c, "clean does not return an object reference");

eval {
  my $foo = $c->struct;
};
ok( $@, qr/without parse data/, "parse data check failed" );
