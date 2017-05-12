#!perl -w

use strict;

use Test::More tests => 1;

# test an Object with an non-array/non-hash sub-object

use Array::To::Moose qw (:ALL);

eval 'use VarianReportsMoose qw(print_obj)';

use Data::Dumper;

use Carp;

package Visit;
use Moose;
use MooseX::StrictConstructor;
has  date      => (is => 'ro', isa => 'Str');
has  doctor    => (is => 'ro', isa => 'Str');
has  diagnosis => (is => 'ro', isa => 'Str');

package Patient;
use Moose;
use MooseX::StrictConstructor;
has last       => (is => 'ro', isa => 'Str');
has first      => (is => 'ro', isa => 'Str');
has FirstVisit => (is => 'ro', isa => 'Visit');

no Moose;

package main;

sub Npat { Patient->new(last => $_[0], first => $_[1], FirstVisit => $_[2] ) }
sub Nvis { Visit->new(date => $_[0], doctor => $_[1], diagnosis => $_[2] ) }

# patients
my @p1 = ( "Smith", "John"  );
my @p2 = ( "Smith", "Alex"  );
my @p3 = ( "Green", "Helen" );

#visits
my @v1 = ( "03/10/2008", "F Jones, M.D.", "Tendonitis"  );
my @v2 = ( "08/17/2008", "F Jones, M.D.", "Tinea Pedis" );

my @v3 = ( "11/28/2008", "L Ho, D.D.S",   "Toothache"   );

my @v4 = ( "07/18/2010", "A. Black M.D.", "RSI"         );
my @v5 = ( "12/12/2010", "A. Black M.D.", "Allergies"   );
my @v6 = ( "02/14/2011", "L Ho, D.D.S.",  "Caries"      );

my $data = [
              [ @p1, @v1 ],

              [ @p2, @v3 ],

              [ @p3, @v4 ],
];

my $expected = [
    Npat(@p1, Nvis(@v1)),
    Npat(@p2, Nvis(@v3)),
    Npat(@p3, Nvis(@v4)),
];

# rows of @$data contain: Last, First, Date, Doctor, Diagnosis
#           at positions: [0]   [1]    [2]   [3]     [4]
#
my $object = array_to_moose(
                        data => $data,
                        desc => {
                          class => 'Patient',
                          last  => 0,
                          first => 1,
                          FirstVisit => {
                            class     => 'Visit',
                            date      => 2,
                            doctor    => 3,
                            diagnosis => 4,
                          },
                        }
);

#print "Object:\n", print_obj($object);
#print "Expected:\n", print_obj($expected);

is_deeply($expected, $object, "obj with an non-array/non-hash sub-obj");
