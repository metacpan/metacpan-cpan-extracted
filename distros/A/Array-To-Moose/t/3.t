#!perl -w

use strict;

use Test::More tests => 3;

# Construct Moose objects with one level only (i.e. no sub-objects),
# as array and hash

eval 'use VarianReportsMoose qw(print_obj)';

use Data::Dumper;

use Array::To::Moose qw (:ALL :TESTING);

package Patient;
use Moose;
use MooseX::StrictConstructor;
use namespace::autoclean;

has [ qw(last first) ] => (is => 'ro', isa => 'Str');

__PACKAGE__->meta->make_immutable;

package main;

sub Npat { Patient->new(last => $_[0], first => $_[1] ) }

# patients
my @p1 = ( "Smith", "John"  );
my @p2 = ( "Smith", "Alex"  );
my @p3 = ( "Green", "Helen" );

my $desc = { class => 'Patient',
             last  => 0,
             first => 1,
           };

########################################
# make a 2-D array (list) with one row into a single Moose Object

my $expected = [ Npat(@p1) ];

my $object = array_to_moose(
                        data => [ \@p1 ],
                        desc => $desc,
);

#print print_obj($object);
#print print_obj($expected);

is_deeply($expected, $object, "single row data array, returning array");

########################################
# make a single-level 2-D array into a Moose array

my $data = [ [ @p1 ], [ @p2 ], [ @p3 ] ];

$expected = [ Npat(@p1), Npat(@p2), Npat(@p3) ];

$object = array_to_moose(
                        data =>  $data,
                        desc => $desc,
);

is_deeply($expected, $object, "2-D single level array, array return");

########################################

sub NpatH { $_[1] => Patient->new(last => $_[0], first => $_[1] ) }

$expected = { NpatH(@p1), NpatH(@p2), NpatH(@p3) };

# we can use first name as key, since they are unique (whew!)
$object = array_to_moose( data =>  $data,
                          desc => {
                            class => 'Patient',
                            key   => 1,
                            last  => 0,
                            first => 1,
                          },
);

#print "obj ", print_obj($object);
#print "expected ", print_obj($expected);

#print "obj ", Dumper($object);
#print "expected ", Dumper($expected);

is_deeply($expected, $object, "2-D single level array, hash return");
