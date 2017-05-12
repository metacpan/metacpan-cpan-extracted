#!/usr/bin/perl

use Test;
BEGIN { plan tests => 11 }

########################################################################

package MyObject;

use Class::MakeMethods::Standard::Hash (
  'new' => 'new',
);

########################################################################
### WAYS OF SPECIFYING A SUBCLASS 
########################################################################

use Class::MakeMethods::Standard::Hash (
  scalar => 'a'
);

use Class::MakeMethods (
  -MakerClass => 'Standard::Hash',
  scalar => 'b',
);

use Class::MakeMethods (
  -MakerClass => '::Class::MakeMethods::Standard::Hash',
  scalar => 'c',
);

use Class::MakeMethods (
  'Standard::Hash:scalar' => 'd',
);

use Class::MakeMethods (
  '::Class::MakeMethods::Standard::Hash:scalar' => 'e',
);

########################################################################
### FORMS OF STANDARD DECLARATION SYNTAX
########################################################################

use Class::MakeMethods::Standard::Hash (
  scalar => 'f'
);

use Class::MakeMethods::Standard::Hash (
  scalar => [ 'g' ]
);

use Class::MakeMethods::Standard::Hash (
  scalar => [ h => { hash_key => "__h" } ]
);

use Class::MakeMethods::Standard::Hash (
  scalar => { 'name' => 'i', hash_key => "__i" }
);

use Class::MakeMethods::Standard::Hash (
  scalar => [ { 'name' => 'j', hash_key => "__j" } ]
);

########################################################################

package main;

ok( 1 );

my $i;
my $o = MyObject->new( map { $_ => ++ $i  } qw ( a b c d e f g h i j ) );

ok( $o->a(), 1 );
ok( $o->b(), 2 );
ok( $o->c(), 3 );
ok( $o->d(), 4 );
ok( $o->e(), 5 );

ok( $o->f(), 6 );
ok( $o->g(), 7 );
ok( $o->h(), 8 );
ok( $o->i(), 9 );
ok( $o->j(), 10 );
