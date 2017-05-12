#!perl -w

use strict;

use Test::More;

# test mismatch between data and attribute types, e.g., 'Int' attributes,
# non-integer data


use Array::To::Moose qw (:ALL);

BEGIN {
  eval "use Test::Exception";
  plan skip_all => "Test::Exception needed" if $@;
}

plan tests => 2;

eval 'use VarianReportsMoose qw(print_obj)';

use Data::Dumper;

use Carp;

package Point;
use namespace::autoclean;
use Moose;
use MooseX::StrictConstructor;
has 'x' => (is => 'ro', isa => 'Int');
has 'y' => (is => 'ro', isa => 'Int');

__PACKAGE__->meta->make_immutable;

package main;

sub Npt { Point->new(x => $_[0], y => $_[1]) }

my @p1 = ( 1, 2 );
my @p2 = ( 3, 4 );
my @p3 = ( 5, 6 );

my $idata = [ \@p1, \@p2, \@p3 ];

my $sdata = [
  [ "Smith", "John"  ],
  [ "Smith", "Alex"  ],
  [ "Green", "Helen" ],
];

my $desc = { class => 'Point', x => 0, y => 1, };

my $object = array_to_moose( data => $idata, desc => $desc);

my $expected = [ Npt(@p1), Npt(@p2), Npt(@p3) ];

#print "Object:\n", print_obj($object);
#print "Expected:\n", print_obj($expected);

is_deeply($expected, $object,
        "make point array from integer data");


throws_ok { array_to_moose( data => $sdata, desc => $desc) }
          qr/Can't make a new 'Point' object/,
          "Can't load non-integer data into integer attributes (very weak test)";
