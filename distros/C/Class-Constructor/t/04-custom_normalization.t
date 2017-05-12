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

Test_Class->mk_constructor(
    Auto_Init              => [ qw/ foo BAR Baz / ],
    Method_Name_Normalizer => sub { "_method_" . (uc $_[0]) },
    Param_Name_Normalizer  => sub { "_param_" . (lc $_[0]) },
    Class_Name_Normalizer  => sub { "_class_" . (uc $_[0])  },
);

sub _method_FOO { $_[0]->{xfoo} = $_[1] if defined $_[1]; return $_[0]->{xfoo} }
sub _method_BAR { $_[0]->{xbar} = $_[1] if defined $_[1]; return $_[0]->{xbar} }
sub _method_BAZ { $_[0]->{xbaz} = $_[1] if defined $_[1]; return $_[0]->{xbaz} }

package main;


my $tc = Test_Class->new(
    fOO => 'testfoo',
    bar => 'testbar',
    BAZ => 'testbaz',
);

is(ref $tc, 'Test_Class', 'class1 - object created');
is($tc->_method_FOO, 'testfoo', 'class1 - attr1');
is($tc->_method_BAR, 'testbar', 'class1 - attr2');
is($tc->_method_BAZ, 'testbaz', 'class1 - attr3');


package Subclass_Test;
use base qw/ Class::Constructor /;

sub _method_BAZ { $_[0]->{xbaz} = $_[1] if defined $_[1]; return $_[0]->{xbaz} }
sub _method_BAM { $_[0]->{xbam} = $_[1] if defined $_[1]; return $_[0]->{xbam} }
sub _method_TYPE { $_[0]->{xtype} = $_[1] if defined $_[1]; return $_[0]->{xtype} }

Subclass_Test->mk_constructor(
    Name                   => 'create',
    Subclass_Param         => 'type',
    Auto_Init              => [ qw/ BAZ baM TypE / ],
    Method_Name_Normalizer => sub { "_method_" . (uc $_[0]) },
    Param_Name_Normalizer  => sub { "_param_" . (lc $_[0]) },
    Class_Name_Normalizer  => sub { "_class_" . (uc $_[0])  },
);

sub set_bam {
    my $self = shift;
    $self->_method_BAM('no');
};

sub set_baz {
    my $self = shift;
    $self->_method_BAZ('no');
};

package main;

$tc = Subclass_Test->create(
    Baz  => 'testbaz',
    bAm  => 'testbam',
);

$tc->set_bam;
$tc->set_baz;

is(ref $tc, 'Subclass_Test', 'non-subclassed object - object created');
is($tc->_method_BAM,'no', 'subclass - non-subclassed object method 1');
is($tc->_method_BAZ,'no', 'subclass - non-subclassed object method 2');

$tc = Subclass_Test->create(
    bAz          => 'testbaz',
    bAm          => 'testbam',
    TyPe         => 'Subclass1',
);

$tc->set_bam;
$tc->set_baz;

is(ref $tc, 'Subclass_Test::_class_SUBCLASS1', 'non-subclassed object - object created');
is($tc->_method_BAM,'yes', 'subclass - overridden method');
is($tc->_method_BAZ,'no',  'subclass - non-overridden method');
is($tc->_method_TYPE,'Subclass1',  'subclass - Type available as method');

