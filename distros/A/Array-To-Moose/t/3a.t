#!perl -w

use strict;

use Test::More tests => 4;

# one-level data only, but using different "class" and "key" keywords
# and also testing that the defaults get reset OK

eval 'use VarianReportsMoose qw(print_obj)';

use Data::Dumper;

use Array::To::Moose qw (:ALL :TESTING);

# change keywords "class" to "_CLASS_" and "key" to "_KEY_"
set_class_ind('_CLASS_');
set_key_ind('_KEY_');

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


########################################
# make a 2-D array with a single row into a single Moose Object

my $expected = [ Npat(@p1) ];

my $object = array_to_moose(
                        data => [ \@p1 ],
                        desc => {
                          _CLASS_ => 'Patient',  # changed indicator
                          last  => 0,
                          first => 1,
                         },
);

#print print_obj($object);
#print print_obj($expected);

is_deeply($expected, $object,
    "1-D data array, returning array, 'class' redefined");

########################################
# make a single-level 2-D array into a Moose array

my $data = [ [ @p1 ], [ @p2 ], [ @p3 ] ];

$expected = [ Npat(@p1), Npat(@p2), Npat(@p3) ];

$object = array_to_moose(
                        data =>  $data,
                        desc => {
                          _CLASS_ => 'Patient',
                          last  => 0,
                          first => 1,
                        }
);

is_deeply($expected, $object,
    "2-D single level array, array return, 'class' redefined");

########################################

sub NpatH { $_[1] => Patient->new(last => $_[0], first => $_[1] ) }

$expected = { NpatH(@p1), NpatH(@p2), NpatH(@p3) };

# we can use first name as key, since they are unique (whew!)
$object = array_to_moose( data =>  $data,
                          desc => {
                            _CLASS_ => 'Patient',
                            _KEY_   => 1,
                            last  => 0,
                            first => 1,
                          },
);

is_deeply($expected, $object,
    "2-D single level array, hash return, 'class' and 'key' redefined");

########################################
# reset the key words and re-run only last test

set_class_ind();
set_key_ind();

$object = array_to_moose( data =>  $data,
                          desc => {
                            class => 'Patient',
                            key   => 1,
                            last  => 0,
                            first => 1,
                          },
);

is_deeply($expected, $object,
    "2-D single level array, hash return, with 'class' and 'key' reset");
