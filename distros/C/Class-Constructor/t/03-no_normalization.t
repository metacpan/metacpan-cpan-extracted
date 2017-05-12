#!/usr/bin/perl

use strict;
use 5.005;
# use Cwd;

use File::Spec;
use lib File::Spec->join('t', 'lib');
use lib 'lib';

# use Test::More qw(no_plan);
use Test::More tests => 12;

BEGIN { use_ok('Class::Constructor'); }

package Test_Class;
use base qw/ Class::Constructor /;

sub foo { $_[0]->{foo} = $_[1] if defined $_[1]; return $_[0]->{foo} }
sub FOO { $_[0]->{FOO} = $_[1] if defined $_[1]; return $_[0]->{FOO} }
sub Foo { $_[0]->{Foo} = $_[1] if defined $_[1]; return $_[0]->{Foo} }

Test_Class->mk_constructor(
    Auto_Init                  => [ qw/ foo FOO Foo / ],
    Disable_Name_Normalization => 1,
);

package main;

my $tc = Test_Class->new(
    foo => 'testfoo',
    FOO => 'testFOO',
    Foo => 'testFoo',
);

is(ref $tc, 'Test_Class', 'class1 - object created');
is($tc->foo, 'testfoo', 'class1 - attr1');
is($tc->FOO, 'testFOO', 'class1 - attr2');
is($tc->Foo, 'testFoo', 'class1 - attr3');


package Subclass_Test;
use base qw/ Class::Constructor /;

sub Type { $_[0]->{Type} = $_[1] if defined $_[1]; return $_[0]->{Type} }
sub TYPE { $_[0]->{TYPE} = $_[1] if defined $_[1]; return $_[0]->{TYPE} }
sub TyPe { $_[0]->{TyPe} = $_[1] if defined $_[1]; return $_[0]->{TyPe} }

Subclass_Test->mk_constructor(
    Name                  => 'create',
    Subclass_Param        => 'TyPe',
    Auto_Init             => [ qw/ Type TYPE TyPe / ],
    Disable_Case_Mangling => 1,
);

sub set_Type {
    my $self = shift;
    $self->Type('no');
};

sub set_TYPE {
    my $self = shift;
    $self->TYPE('no');
};

package main;

$tc = Subclass_Test->create(
    Type  => 'testType',
    TYPE  => 'testTYPE',
);

$tc->set_Type;
$tc->set_TYPE;

is(ref $tc, 'Subclass_Test', 'non-subclassed object - object created');
is($tc->Type,'no', 'subclass - non-subclassed object method 1');
is($tc->TYPE,'no', 'subclass - non-subclassed object method 2');

$tc = Subclass_Test->create(
    Type  => 'testType',
    TYPE  => 'testTYPE',
    TyPe  => 'Subclass1',
);

$tc->set_Type;
$tc->set_TYPE;

is(ref $tc, 'Subclass_Test::Subclass1', 'non-subclassed object - object created');
is($tc->Type,'yes', 'subclass - overridden method');
is($tc->TYPE,'no',  'subclass - non-overridden method');
is($tc->TyPe,'Subclass1',  'subclass - Type available as method');




