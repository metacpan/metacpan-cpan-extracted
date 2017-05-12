#!perl -w

use strict;

use Test::More tests => 1;

# Simple test of an Object 3 levels deep (Patient->Visit->Test) for the POD

use Array::To::Moose qw (:ALL);

eval 'use VarianReportsMoose qw(print_obj)';

use Data::Dumper;

use Carp;

#------------
package Test;
use Moose;
use MooseX::StrictConstructor;
use namespace::autoclean;

has 'name'        => (is => 'rw', isa => 'Str');
has 'result'      => (is => 'rw', isa => 'Str');

#------------
package Visit;
use Moose;
use MooseX::StrictConstructor;
use namespace::autoclean;

has 'date'        => (is => 'rw', isa => 'Str'           );
has 'md'          => (is => 'rw', isa => 'Str'           );
has 'diagnosis'   => (is => 'rw', isa => 'Str'           );
has 'Tests'       => (is => 'rw', isa => 'HashRef[Test]' );

#------------
package Patient;
use Moose;
use MooseX::StrictConstructor;
use namespace::autoclean;

has 'last'        => (is => 'rw', isa => 'Str'             );
has 'first'       => (is => 'rw', isa => 'Str'             );
has 'Visits'      => (is => 'rw', isa => 'ArrayRef[Visit]' );

Test   ->meta->make_immutable;
Visit  ->meta->make_immutable;
Patient->meta->make_immutable;

package main;

#      patient      |               visit           |      test
#    last     first |  visit_date   md_name         | name     result
#    0       1         2            3                 4        5
my $data = [
  [ "Smith", "John",  "03/10/2008", "F Jones, M.D.", "Weight", 185      ],
  [ "Smith", "John",  "03/10/2008", "F Jones, M.D.", "Pulse",  72       ],
  [ "Smith", "John",  "03/10/2008", "F Jones, M.D.", "BP",     "120/80" ],
  [ "Smith", "Alex",  "08/17/2008", "F Jones, M.D.", "PSA",    3.4      ],
  [ "Green", "Helen", "11/28/2008", "L Ho, D.D.S",   "BP",     "128/88" ],
  [ "Green", "Helen", "11/28/2008", "L Ho, D.D.S",   "HDL",    105      ],
  [ "Green", "Helen", "11/28/2008", "L Ho, D.D.S",   "LDL",    80       ],
];


my $patients = array_to_moose(
                    data => $data,
                    desc => {
                      class => 'Patient',
                      last  => 0,
                      first => 1,
                      Visits => {
                        class => 'Visit',
                        date      => 2,
                        md        => 3,
                        Tests => {
                          class  => 'Test',
                          key    => 4,
                          name   => 4,
                          result => 5,
                        } # tests
                      } # visits
                    } # patients
);

is($patients->[2]->Visits->[0]->Tests->{BP}->result,
   '128/88',
   'correct result given'
);
