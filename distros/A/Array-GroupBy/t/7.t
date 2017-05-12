#!perl -w

use strict;

use Test::More;

BEGIN {
    eval "use Moose";
    plan skip_all => "Moose needed" if $@;
}

BEGIN {
    eval "use MooseX::StrictConstructor";
    plan skip_all => "MooseX::StrictConstructor::Exception needed" if $@;
}
  
plan tests => 1;

#use Test::Exception;
#use List::Util qw(max);

use Array::GroupBy qw(igroup_by str_row_equal);

#
# Example 4 - Building Moose objects
#

package Visit;
use Moose;
use MooseX::StrictConstructor;
has  date      => (is => 'ro', isa => 'Str');
has  doctor    => (is => 'ro', isa => 'Str');
has  diagnosis => (is => 'ro', isa => 'Str');

package Patient;
use Moose;
use MooseX::StrictConstructor;
has last      => (is => 'ro', isa => 'Str');
has first     => (is => 'ro', isa => 'Str');
has Visits    => (is => 'ro', isa => 'ArrayRef[Visit]');

no Moose;

package main;

use Data::Dumper;

sub Npat { Patient->new(last => $_[0], first => $_[1], Visits => $_[2] ) }
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
              [ @p1, @v2],

              [ @p2, @v3 ],

              [ @p3, @v4 ],
              [ @p3, @v5 ],
              [ @p3, @v6 ],
];

my $obj = [
    Npat(@p1, [ Nvis(@v1), Nvis(@v2) ] ),
    Npat(@p2, [ Nvis(@v3) ] ),
    Npat(@p3, [ Nvis(@v4), Nvis(@v5), Nvis(@v6) ] ),
];

# small data & object
#$data = [ [ @p1, @v1 ], [ @p1, @v2] ];
#$obj = [ Npat(@p1, [ Nvis(@v1), Nvis(@v2) ] ) ];

#print Dumper($obj);

#print Dumper($data);

my @result;

# rows of @$data contain: Last, First, Date, Doctor, Diagnosis
#           at positions: [0]   [1]    [2]   [3]     [4]

my $iter = igroup_by(
              data    => $data,
              compare => \&str_row_equal,
              args    => [ 0, 1 ],
                    );

while (my $subset = $iter->()) {

  my @visits = map { Visit->new(
                      date        => $_->[2],
                      doctor      => $_->[3],
                      diagnosis   => $_->[4],
                               )
                   } @$subset;

  push @result, Patient->new(
                      last  => $subset->[0]->[0],
                      first => $subset->[0]->[1],
                      Visits => \@visits,
                            );
}
#print Dumper(\@result);

## The test ##
is_deeply(\@result, $obj, "build Moose object");
