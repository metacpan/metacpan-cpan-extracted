#!/usr/bin/perl

use Test;
BEGIN { plan tests => 12 }

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
### FORMS OF SIMPLE DECLARATION SYNTAX
########################################################################

use Class::MakeMethods::Standard::Hash (
  scalar => 'f'
);

use Class::MakeMethods::Standard::Hash (
  scalar => [ 'g' ]
);

use Class::MakeMethods::Standard::Hash (
  scalar => 'h i'
);

use Class::MakeMethods::Standard::Hash (
  scalar => [ 'j', 'k' ]
);

########################################################################

package main;

ok( 1 );

my $i;
my $o = MyObject->new( map { $_ => ++ $i  } qw ( a b c d e f g h i j k ) );

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
ok( $o->k(), 11 );
