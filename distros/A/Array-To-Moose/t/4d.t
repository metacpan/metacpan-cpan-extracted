#!perl -w

use strict;

use Test::More;

BEGIN {
    eval "use Test::Exception";
      plan skip_all => "Test::Exception needed" if $@;
}

plan tests => 7;

# tests on single-level Objects with a ref attribute

use Array::To::Moose qw (:ALL);

eval 'use VarianReportsMoose qw(print_obj)';

use Data::Dumper;

use Carp;

package Person;
use Moose;
use namespace::autoclean;
use MooseX::StrictConstructor;
has last      => (is => 'ro', isa => 'Str');
has first     => (is => 'ro', isa => 'Str');
has hobbies   => (is => 'ro', isa => 'ArrayRef[Str]');

__PACKAGE__->meta->make_immutable;

package main;

sub Npat { Person->new(last => $_[0], first => $_[1], hobbies => $_[2] ) }

# person
my @p1 = ( "Smith", "John"  );
my @p2 = ( "Smith", "Alex"  );
my @p3 = ( "Green", "Helen" );

# hobbies
my $h1 = 'Walking';
my $h2 = 'Cooking';

my $h3 = 'Cycling';

my $h4 = 'Quilting';
my $h5 = 'Baking';
my $h6 = 'Running';

my @h1 = ( $h1, $h2      );
my @h2 = ( $h3           );
my @h3 = ( $h4, $h5, $h6 );


my $data = [
              [ @p1, $h1 ],
              [ @p1, $h2],

              [ @p2, $h3 ],

              [ @p3, $h4 ],
              [ @p3, $h5 ],
              [ @p3, $h6 ],
];

my $expected = [
    Npat(@p1, [ @h1 ] ),
    Npat(@p2, [ @h2 ] ),
    Npat(@p3, [ @h3 ] ),
];

# rows of @$data contain: last, first, hobbies
#           at positions: [0]   [1]    [2]
#

my $object;
lives_ok {
    $object = array_to_moose(
                          data => $data,
                          desc => {
                            class => 'Person',
                            last  => 0,
                            first => 1,
                            hobbies => [2],
                          }
                             )
         } "'Person' with 'hobbies'";

#print "Object:\n", print_obj($object);
#print "Expected:\n", print_obj($expected);

is_deeply($expected, $object, "obj with an ArrayRef[Str] attribute");

#
# Error tests
#

# Forgot '[]' in hobbies => descriptor line
throws_ok { array_to_moose(
                        data => $data,
                        desc => {
                          class   => 'Person',
                          last    => 0,
                          first   => 1,
                          hobbies => 2,     # Oops! should be '[2]'
                        }
                          );
           }
  qr/'Person'.*Did you forget/,
  "Moose object with 'ArrayRef[Str]' attribute but no '[]' in desc";


# has attribute 'no_type' which has - No Type!
package Person_no_type;
use namespace::autoclean;
use Moose;
use MooseX::StrictConstructor;

extends 'Person';

has 'no_type' => ( is => 'rw' );  # no isa => ...

__PACKAGE__->meta->make_immutable;

package main;

throws_ok { array_to_moose(
                        data => $data,
                        desc => {
                          class => 'Person_no_type',
                          last  => 0,
                          first => 1,
                          no_type => [2],
                        }
                          );
           }
  qr/'Person_no_type' ref attrib 'no_type' has no type constraint/,
  "Moose ref attribute has no type";


# has attribute 'non_simple' which is an arrayref of type
# non-defined class 'Blah'
package Person_non_simple_att;
use namespace::autoclean;
use Moose;
use MooseX::StrictConstructor;

extends 'Person';

has 'non_simple' => ( is => 'rw', isa => 'ArrayRef[Blah]' );

__PACKAGE__->meta->make_immutable;

package main;

throws_ok { array_to_moose(
                        data => $data,
                        desc => {
                          class => 'Person_non_simple_att',
                          last       => 0,
                          first      => 1,
                          non_simple => [2],
                        }
                          );
           }
  qr/'Person_non_simple_att' .* not a simple type/,
  "Moose simple attribute has non-simple type";


# make attribute 'non_simple' an arrayref of a defined class 'Person_no_type'
package Person_non_simple_att_1;
use namespace::autoclean;
use Moose;
use MooseX::StrictConstructor;

extends 'Person';

has 'non_simple' => ( is => 'rw', isa => 'ArrayRef[Person_no_type]' );

__PACKAGE__->meta->make_immutable;

package main;

throws_ok { array_to_moose(
                        data => $data,
                        desc => {
                          class => 'Person_non_simple_att_1',
                          last       => 0,
                          first      => 1,
                          non_simple => [2],
                        }
                          );
           }
  qr/'Person_non_simple_att_1' .* not a simple type/,
  "Moose simple attribute has non-simple (but defined) type";

# make attribute 'non_arrayref' a HashRef
package Person_w_hashref;
use namespace::autoclean;
use Moose;
use MooseX::StrictConstructor;

extends 'Person';

has 'non_simple' => ( is => 'rw', isa => 'HashRef[Blah]' );

__PACKAGE__->meta->make_immutable;

package main;

throws_ok { array_to_moose(
                        data => $data,
                        desc => {
                          class => 'Person_w_hashref',
                          last       => 0,
                          first      => 1,
                          non_simple => [2],
                        }
                          );
           }
  qr/'Person_w_hashref' .* not a 'HashRef/,
  "Moose simple attribute is hashref";
