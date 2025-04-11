#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use English qw( -no_match_vars );

{

  package BaseThing;

  use strict;
  use warnings;

  our %ATTRIBUTES = (
    id   => 1,
    type => 0,
  );

  __PACKAGE__->follow_best_practice;
  __PACKAGE__->mk_accessors( keys %ATTRIBUTES );

  use parent qw(Class::Accessor::Validated Class::Accessor::Fast);

  1;
}

{

  package SubThing;

  use strict;
  use warnings;

  our %ATTRIBUTES = ( name => 1, );

  Class::Accessor->follow_best_practice(__PACKAGE__);
  Class::Accessor->mk_accessors( __PACKAGE__, keys %ATTRIBUTES );

  our @ISA = qw( BaseThing Class::Accessor );
  1;
}

{

  package My::Thing;

  use strict;
  use warnings;

  our %ATTRIBUTES = (
    name  => 1,
    color => 0,
  );

  __PACKAGE__->follow_best_practice;
  __PACKAGE__->mk_accessors( keys %ATTRIBUTES );

  use parent qw(Class::Accessor::Validated Class::Accessor::Fast);

  1;
}

package main;

########################################################################
subtest 'valid construction' => sub {
########################################################################
  my $thing;
  ok(
    eval {
      $thing = My::Thing->new( { name => 'Widget', color => 'blue' } );
      1;
    },
    'constructor succeeds with required and optional keys'
  ) or diag $EVAL_ERROR;

  is( $thing->get_name,  'Widget', 'get_name returns correct value' );
  is( $thing->get_color, 'blue',   'get_color returns correct value' );
};

########################################################################
subtest 'missing required key' => sub {
########################################################################
  ok( !eval { My::Thing->new( { color => 'red' } ); }, 'constructor dies when required key is missing' );
  like( $EVAL_ERROR, qr/required\sargument[(]s[)]:\sname/xsm, 'error includes missing key' );
};

########################################################################
subtest 'unexpected key' => sub {
########################################################################
  ok( !eval { My::Thing->new( { name => 'Oops', fluff => 'none' } ); },
    'constructor dies when unknown key is passed' );
  like( $EVAL_ERROR, qr/invalid\sargument[(]s[)]:\sfluff/xsm, 'error includes unexpected key' );
};

########################################################################
subtest 'all valid keys' => sub {
########################################################################
  ok(
    eval {
      My::Thing->new( { name => 'Full', color => 'green' } );
      1;
    },
    'constructor accepts all valid keys'
  ) or diag $EVAL_ERROR;
};

########################################################################
subtest 'inherited attributes' => sub {
########################################################################
  my $obj;
  ok(
    eval {
      $obj = SubThing->new( { id => 123, name => 'nested' } );
      1;
    },
    'constructor accepts inherited and local attributes'
  ) or diag $EVAL_ERROR;

  is( $obj->get_id,   123,      'get_id works from base class' );
  is( $obj->get_name, 'nested', 'get_name works from subclass' );

  ok(
    !eval {
      SubThing->new( { name => 'only' } );  # missing 'id'
    },
    'constructor fails when inherited required key is missing'
  );
  like( $EVAL_ERROR, qr/required\sargument[(]s[)]:\sid/xsm, 'error includes inherited required key' );
};

done_testing;

1;
