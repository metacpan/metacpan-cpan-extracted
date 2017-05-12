#!perl -w

use strict;

use Test::More tests => 1;

# test an Object 3 levels deep (Patient->Visit->Test)

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
has 'result'      => (is => 'rw', isa => 'Num');

#------------
package Visit;
use Moose;
use MooseX::StrictConstructor;
use namespace::autoclean;

has 'date'     => (is => 'rw', isa => 'Str'            );
has 'md'       => (is => 'rw', isa => 'Str'            );
has 'Tests'    => (is => 'rw', isa => 'ArrayRef[Test]' );

#------------
package Patient;
use Moose;
use MooseX::StrictConstructor;
use namespace::autoclean;

has 'last'        => (is => 'rw', isa => 'Str'            );
has 'first'       => (is => 'rw', isa => 'Str'            );
has 'Visits'      => (is => 'rw', isa => 'ArrayRef[Visit]' );

Test   ->meta->make_immutable;
Visit  ->meta->make_immutable;
Patient->meta->make_immutable;

package main;

#   patient  |    visit    |   test
# last  first|visit_date md|name result
# 0     1     2          3  4    5    <- column index

package main;

sub Npat { Patient->new(last => $_[0], first => $_[1], Visits => $_[2] ) }
sub Nvis {   Visit->new(date => $_[0], md    => $_[1], Tests => $_[2]  ) }
sub Ntst {    Test->new(name => $_[0], result => $_[1]                 ) }

# patients
my @p1 = ( "Smith", "John"  );
my @p2 = ( "Smith", "Alex"  );
my @p3 = ( "Green", "Helen" );

#visits
my @v1 = ( "03/10/2008", "F Jones, M.D." );
my @v2 = ( "08/17/2008", "F Jones, M.D." );

my @v3 = ( "11/28/2008", "L Ho, D.D.S"   );

my @v4 = ( "07/18/2010", "A. Black M.D." );
my @v5 = ( "12/12/2010", "A. Black M.D." );
my @v6 = ( "02/14/2011", "L Ho, D.D.S."  );

#tests
my @t1 = ( "test1", 1.1 );
my @t2 = ( "test2", 2.1 );
my @t3 = ( "test3", 3.1 );
my @t4 = ( "test4", 4.1 );
my @t5 = ( "test5", 5.1 );
my @t6 = ( "test6", 6.1 );
my @t7 = ( "test7", 7.1 );
my @t8 = ( "test8", 8.1 );
my @t9 = ( "test9", 9.1 );

my $data = [
              # p1
              [ @p1, @v1, @t1 ],
              [ @p1, @v1, @t2 ],
              [ @p1, @v1, @t3 ],

              [ @p1, @v2, @t4 ],
              [ @p1, @v2, @t5 ],

              # p2
              [ @p2, @v3, @t5 ],
              [ @p2, @v3, @t6 ],
              [ @p2, @v3, @t7 ],

              # p3
              [ @p3, @v4, @t1 ],
              [ @p3, @v4, @t2 ],
              [ @p3, @v4, @t3 ],

              [ @p3, @v5, @t4 ],
              [ @p3, @v5, @t5 ],
              [ @p3, @v5, @t6 ],
              [ @p3, @v5, @t7 ],

              [ @p3, @v6, @t8 ],
              [ @p3, @v6, @t9 ],
];

my $expected = [
    Npat(@p1, [ Nvis( @v1, [ Ntst(@t1),
                             Ntst(@t2),
                             Ntst(@t3),
                           ]
                    ),

                Nvis( @v2, [ Ntst(@t4),
                             Ntst(@t5)
                           ]
                     ),
              ]
        ),

    Npat(@p2, [ Nvis( @v3, [ Ntst(@t5),
                             Ntst(@t6),
                             Ntst(@t7)
                           ]
                    ),
              ]
        ),

    Npat(@p3, [ Nvis(@v4, [ Ntst(@t1),
                            Ntst(@t2),
                            Ntst(@t3)
                          ]
                    ),
                Nvis(@v5, [ Ntst(@t4),
                            Ntst(@t5),
                            Ntst(@t6),
                            Ntst(@t7)
                          ]
                    ),
                Nvis(@v6, [ Ntst(@t8),
                            Ntst(@t9)
                          ]
                    )
              ]
        ),
];


# <-    patient    -> <-  visit  -> <- test  ->
# patient_id name age md visit_date name result
# 0          1    2   3  4          5    6      <- column index

my $object = array_to_moose(
                        data => $data,
                        desc => {
                          class => 'Patient',
                          last  => 0,
                          first => 1,
                          Visits => {
                            class => 'Visit',
                            date  => 2,
                            md    => 3,
                            Tests => {
                              class  => 'Test',
                              name   => 4,
                              result => 5,
                            } # tests
                          } # visits
                        } # patients
);

#print "Object:\n", print_obj($object);
#print "Expected:\n", print_obj($expected);

is_deeply($expected, $object, "obj with an ArrayRef sub-obj");

