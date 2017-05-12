################################################################################
#
# Copyright (c) 2002-2015 Marcus Holland-Moritz. All rights reserved.
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
################################################################################

use Test;
use Convert::Binary::C @ARGV;

$^W = 1;

BEGIN { plan tests => 30 }

eval { $p = new Convert::Binary::C; };
ok($@,'',"failed to create Convert::Binary::C object");

eval {
$p->parse(<<'EOF');
struct floating {
  struct {
    char   a;
    float  b;
    double c;
  }      a[4];
  float  b[4];
  double c[4];
};
EOF
};
ok($@,'',"parse() failed");

$data = {
  a => [
         { a => 42, b => -5.0    , c =>  4.2e33  },
         { a => 43, b =>  1.5    , c =>  3.14159 },
         { a => 44, b =>  3.14159, c =>  1.5     },
         { a => 45, b =>  4.2e33 , c => -5.0     },
       ],
  b => [-5.0, 1.5, 3.14159, 4.2e33],
  c => [-5.0, 1.5, 3.14159, 4.2e33],
};

$packed   = $p->pack( 'floating', $data );
$unpacked = $p->unpack( 'floating', $packed );

reccmp( $data, $unpacked );

sub reccmp
{
  my($ref, $val) = @_;

  my $id = ref $ref;

  unless( $id ) {
    # special treatment because floats can be inaccurate
    abs( ($ref - $val) / $ref ) < 1e-6 ? ok(1) : ok($val, $ref);
    return;
  }

  if( $id eq 'ARRAY' ) {
    ok( @$ref == @$val );
    for( 0..$#$ref ) {
      reccmp( $ref->[$_], $val->[$_] );
    }
  }
  elsif( $id eq 'HASH' ) {
    ok( @{[keys %$ref]} == @{[keys %$val]} );
    for( keys %$ref ) {
      reccmp( $ref->{$_}, $val->{$_} );
    }
  }
}
