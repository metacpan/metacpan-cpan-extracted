# 03_class_hierarchy.t
#
# Tests the hierarchal class initialization code

use Test::More tests => 22;

use strict;
use warnings;

our $counter1 = 0;
our $counter2 = 0;

package MyClass;

use Class::EHierarchy qw(:all);
use vars qw(@ISA);

@ISA = qw(Class::EHierarchy);

sub _initialize {
    my $obj = shift;

    #warn "Initializing MyClass for $obj\n";
    $counter1 = 200;
}

sub _deconstruct {
    my $obj = shift;

    #warn "Deconstructing MyClass for $obj\n";
    $counter1 = 100;
}

package MySubClass;

use Class::EHierarchy qw(:all);
use vars qw(@ISA);

@ISA = qw(MyClass);

sub _initialize {
    my $obj = shift;

    #warn "Initializing MySubClass for $obj\n";
    $counter2 = $counter1**2;
}

sub _deconstruct {
    my $obj = shift;

    #warn "Deconstructing MySubClass for $obj\n";
    $counter2 = $counter1 / 4;
}

package main;

my @objects;
my $obj1 = new MyClass;
ok( $obj1, 'create parent 1' );
is( $counter1, 200, 'counter1 check 1' );
is( $counter2, 0,   'counter2 check 1' );
my $obj2 = new MySubClass;
ok( $obj2,               'create child 1' );
ok( $obj1->adopt($obj2), 'adopt child 1' );
is( $counter1, 200,   'counter1 check 2' );
is( $counter2, 40000, 'counter2 check 2' );
@objects = Class::EHierarchy::_dumpObjects();
is( @objects, 2, 'object count 1' );
@objects = ();
$obj2    = undef;
is( $counter1, 200,   'counter1 check 3' );
is( $counter2, 40000, 'counter2 check 3' );
@objects = Class::EHierarchy::_dumpObjects();
is( @objects, 2, 'object count 2' );
@objects = ();
$obj1    = undef;
is( $counter1, 100, 'counter1 check 4' );
is( $counter2, 50,  'counter2 check 4' );
@objects = Class::EHierarchy::_dumpObjects();
is( @objects, 0, 'object count 3' );
@objects = ();

$obj1 = new MyClass;
$obj2 = new MySubClass;
ok( $obj1,               'create parent 2' );
ok( $obj2,               'create child 2' );
ok( $obj1->adopt($obj2), 'adopt child 2' );
$obj2    = undef;
@objects = Class::EHierarchy::_dumpObjects();
is( @objects, 2, 'object count 4' );
@objects = ();
ok( $obj1->disown( $obj1->children ), 'disown child 1' );
@objects = Class::EHierarchy::_dumpObjects();
is( @objects, 1, 'object count 5' );

ok( MySubClass->conceive($obj1), 'conceive child 1' );
@objects = Class::EHierarchy::_dumpObjects();
is( @objects, 2, 'object count 6' );

