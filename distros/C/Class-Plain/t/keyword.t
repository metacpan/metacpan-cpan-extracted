#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use FindBin;
use lib "$FindBin::Bin/lib";

use Class::Plain;

# B module has the class function
use B;

{
   ok( !eval <<'EOPERL',
      field field;
EOPERL
      'field outside class fails' );
   like( $@, qr/^Cannot 'field' outside of 'class' at /,
      'message from failure of field' );
}

# RT132337
{
   ok( !eval <<'EOPERL',
      class AClass { }
      field field;
EOPERL
      'field after closed class block fails' );
   like( $@, qr/^Cannot 'field' outside of 'class' at /);
}

{
   ok( !eval <<'EOPERL',
      method m() { }
EOPERL
      'method outside class fails' );
   like( $@, qr/^Cannot 'method' outside of 'class' at /,
      'message from failure of method' );
}

# Conflict of the class, method, field keywords
class Foo {
  # B module has the class function
  use B;

  use MyKeyword;
}

role Foo {
  # B module has the class function
  use B;

  use MyKeyword;
}

done_testing;
