#!perl -w

use strict;

use Test::More;

# More testing of internal function _check_descriptor(),
# mostly testing column values, e.g. limits


use Array::To::Moose qw(:TESTING);

BEGIN {
  eval "use Test::Exception";
  plan skip_all => "Test::Exception needed" if $@;
}

plan tests => 12;

#----------------------------------------
package Person;
use namespace::autoclean;
use Moose;
use MooseX::StrictConstructor;

has [ qw( name gender ) ] => (is => 'rw', isa =>          'Str' );
has hobbies               => (is => 'rw', isa => 'ArrayRef[Str]');

__PACKAGE__->meta->make_immutable;

package main;

my $n1 = [ 1, 1, 1 ];
my $n2 = [ 2, 2, 2 ];
my $n3 = [ 3, 3, 3 ];
my $n4 = [ 4, 4, 4 ];

my $data = [ $n1, $n2, $n3, $n4 ];

#
# call errors
#


lives_ok {
  _check_descriptor($data,
      { class => 'Person', name => 0, gender => 1, hobbies => [2] }
                   )
         } '_check_descriptor() with ref attribs OK';

throws_ok {
  _check_descriptor($data, { class => 'Person', name => 3 })
} qr/attribute 'name => 3' greater than # cols in the data \(3\)/s,
  '_check_descriptor() attrib column number too big';

throws_ok {
  _check_descriptor($data, { class => 'Person', hobbies => 3 })
} qr/attribute 'hobbies => 3' greater than # cols in the data \(3\)/s,
  '_check_descriptor() attrib column number too big';

throws_ok {
  _check_descriptor($data, { class => 'Person', key => 3, gender => 2 })
} qr/attribute 'key => 3' greater than # cols in the data \(3\)/s,
  "_check_descriptor() 'key' column number too big";

throws_ok {
  _check_descriptor($data, { class => 'Person', name => -1 })
} qr/attribute 'name => -1' must be a \(non-negative\) integer/s,
  '_check_descriptor() attrib column number negative';

throws_ok {
  _check_descriptor($data, { class => 'Person', hobbies => [-1] })
} qr/attribute 'hobbies => \[ -1 \]'. '-1' must be a \(non-negative\) integer/s,
  '_check_descriptor() ref attrib column number negative';

throws_ok {
  _check_descriptor($data, { class => 'Person', name => 'x' })
  ##_check_descriptor( $n1, { N => 'x' } );
} qr/attribute 'name => x' must be a \(non-negative\) integer/s,
  '_check_descriptor() attrib column not an integer';

throws_ok {
  _check_descriptor($data, { class => 'Person', name => 1.5 })
} qr/attribute 'name => 1.5' must be a \(non-negative\) integer/,
  '_check_descriptor() attrib columns number is fractional';

throws_ok {
  _check_descriptor($data, { class => 'Person', hobbies => [1.5] })
} qr/attribute 'hobbies => \[ 1.5 \]'. '1.5' must be a \(non-negative\) integer/,
  '_check_descriptor() ref attrib column number [N] fractional';

# attribute a sub{} reference
throws_ok {
  _check_descriptor($data, { class => 'Person', hobbies => sub { 3 } })
} qr/attribute 'hobbies' can't be a 'CODE' reference/,
  '_check_descriptor() attrib is a sub {}';

throws_ok {
  _check_descriptor($data, { class => 'Person', hobbies => [3] })
} qr/attribute 'hobbies => \[ 3 \]'.* greater than # cols in the data \(3\)/s,
  '_check_descriptor() attrib column in [] too big';

throws_ok {
  _check_descriptor($data, { class => 'Person', hobbies => [0, 1] })
} qr/attribute must be of form.*single integer/,
  '_check_descriptor() attrib column of form [n, m]';
