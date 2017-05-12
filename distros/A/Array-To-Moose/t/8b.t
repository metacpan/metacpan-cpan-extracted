#!perl -w

use strict;

use Test::More;

# test throw_nonunique_keys()

use Array::To::Moose qw (:ALL);

BEGIN {
  eval "use Test::Exception";
  plan skip_all => "Test::Exception needed" if $@;
}

plan tests => 3;

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
has last       => (is => 'ro', isa => 'Str'            );
has first      => (is => 'ro', isa => 'Str'            );
has Visits     => (is => 'ro', isa => 'HashRef[Visit]' );

no Moose;

package main;

sub Npat { Patient->new(last => $_[0], first => $_[1], Visits => $_[2] ) }
sub NvisH {
    $_[0] =>  Visit->new(date => $_[0], doctor => $_[1], diagnosis => $_[2] )
      }


# patients
my @p1 = ( "Smith", "John"  );
my @p2 = ( "Smith", "Alex"  );
my @p3 = ( "Green", "Helen" );

#visits
my @v1 = ( "03/10/2008", "F Jones, M.D.", "Tendonitis"  );
my @v2 = ( "08/17/2008", "F Jones, M.D.", "Tinea Pedis" );

my @v3 = ( "11/28/2008", "L Ho, D.D.S",   "Toothache"   );

my @v4 = ( "07/18/2010", "A. Black M.D.", "RSI"         ); # same dates
my @v5 = ( "07/18/2010", "A. Black M.D.", "Allergies"   ); # same dates
my @v6 = ( "02/14/2011", "L Ho, D.D.S.",  "Caries"      );

my $data = [
              [ @p1, @v1 ],
              [ @p1, @v2],

              [ @p2, @v3 ],

              [ @p3, @v4 ],
              [ @p3, @v5 ],
              [ @p3, @v6 ],
];

# Note that v4 gets overwritten by v5 because the date key is the same
my $expected = [
    Npat(@p1, { NvisH(@v1), NvisH(@v2) } ),
    Npat(@p2, { NvisH(@v3) } ),
    Npat(@p3, { NvisH(@v5), NvisH(@v6) } ),
];

#
# rows of @$data contain: Last, First, Date, Doctor, Diagnosis
#           at positions: [0]   [1]    [2]   [3]     [4]
#

my $desc = {
  class => 'Patient',
  last  => 0,
  first => 1,
  Visits => {
    class     => 'Visit',
    key       => 2,
    date      => 2,
    doctor    => 3,
    diagnosis => 4,
  },
};

my $object = array_to_moose(
                        data => $data,
                        desc => $desc
);

#print "Object:\n", print_obj($object);
#print "Expected:\n", print_obj($expected);

is_deeply($expected, $object,
      "data with non-unique key - warnings disabled");

# warn of the multiple rows being returned
throw_nonunique_keys();

throws_ok { array_to_moose( data => $data, desc => $desc ) }
          qr/Non-unique key '07.18.2010' in 'Visit' class/,
          "data with non-unique key - warnings enabled";

# make the warnings go away again
throw_nonunique_keys(0);

lives_ok { array_to_moose( data => $data, desc => $desc) }
  "data with non-unique key - warnings turned back off";
