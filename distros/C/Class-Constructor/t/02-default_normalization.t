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
sub bar { $_[0]->{bar} = $_[1] if defined $_[1]; return $_[0]->{bar} }
sub baz { $_[0]->{baz} = $_[1] if defined $_[1]; return $_[0]->{baz} }

Test_Class->mk_constructor(
    Auto_Init => [ qw/ FOo BaR baz / ],
);

package main;

my $tc = Test_Class->new(
    fOO => 'testfoo',
    bar => 'testbar',
    BAZ => 'testbaz',
);

is(ref $tc, 'Test_Class', 'class1 - object created');
is($tc->foo, 'testfoo', 'class1 - attr1');
is($tc->bar, 'testbar', 'class1 - attr2');
is($tc->baz, 'testbaz', 'class1 - attr3');


package Subclass_Test;
use base qw/ Class::Constructor /;

sub baz { $_[0]->{baz} = $_[1] if defined $_[1]; return $_[0]->{baz} }
sub bam { $_[0]->{bam} = $_[1] if defined $_[1]; return $_[0]->{bam} }
sub type { $_[0]->{type} = $_[1] if defined $_[1]; return $_[0]->{type} }

Subclass_Test->mk_constructor(
    Name           => 'create',
    Subclass_Param => 'Type',
    Auto_Init      => [ qw/ BAZ baM TypE / ],
);

sub set_bam {
    my $self = shift;
    $self->bam('no');
};

sub set_baz {
    my $self = shift;
    $self->baz('no');
};

package main;

$tc = Subclass_Test->create(
    Baz  => 'testbaz',
    bAm  => 'testbam',
);

$tc->set_bam;
$tc->set_baz;

is(ref $tc, 'Subclass_Test', 'non-subclassed object - object created');
is($tc->bam,'no', 'subclass - non-subclassed object method 1');
is($tc->baz,'no', 'subclass - non-subclassed object method 2');

$tc = Subclass_Test->create(
    bAz  => 'testbaz',
    bAm  => 'testbam',
    TyPe => 'Subclass1',
);

$tc->set_bam;
$tc->set_baz;

is(ref $tc, 'Subclass_Test::Subclass1', 'non-subclassed object - object created');
is($tc->bam,'yes', 'subclass - overridden method');
is($tc->baz,'no',  'subclass - non-overridden method');
is($tc->type,'Subclass1',  'subclass - Type available as method');




