#!/usr/bin/perl

use strict;
use 5.005;
# use Cwd;

use File::Spec;
use lib File::Spec->join('t', 'lib');
use lib 'lib';

# use Test::More qw(no_plan)
use Test::More tests => 21;

BEGIN { use_ok('Class::Constructor'); }

package Test_Class;
use base qw/ Class::Constructor /;

sub foo { $_[0]->{foo} = $_[1] if defined $_[1]; return $_[0]->{foo} }
sub bar { $_[0]->{bar} = $_[1] if defined $_[1]; return $_[0]->{bar} }
sub baz { $_[0]->{baz} = $_[1] if defined $_[1]; return $_[0]->{baz} }

Test_Class->mk_constructor(
    Auto_Init => [ qw/ foo bar baz / ],
);

package main;

my $tc = Test_Class->new(
    foo => 'testfoo',
    bar => 'testbar',
    baz => 'testbaz',
);

is(ref $tc, 'Test_Class', 'class1 - object created');
is($tc->foo, 'testfoo', 'class1 - attr1');
is($tc->bar, 'testbar', 'class1 - attr2');
is($tc->baz, 'testbaz', 'class1 - attr3');


package Test_Class2;
use base qw/ Class::Constructor /;

sub baz { $_[0]->{baz} = $_[1] if defined $_[1]; return $_[0]->{baz} }
sub bam { $_[0]->{bam} = $_[1] if defined $_[1]; return $_[0]->{bam} }

Test_Class2->mk_constructor(
    Name      => 'create',
    Auto_Init => [ qw / baz bam / ],
);

Test_Class2->mk_constructor(
    Name      => 'boom',
    Auto_Init => 'baz',
);

package main;

$tc = Test_Class2->create(
    baz => 'testbaz',
    bam => 'testbam',
);

is(ref $tc, 'Test_Class2', 'class2 - object created');
is($tc->baz, 'testbaz', 'class2 - attr1');
is($tc->bam, 'testbam', 'class2 - attr2');

my $tc2 = Test_Class2->boom(
    baz => 'testbaz',
);

is(ref $tc, 'Test_Class2', 'object created');

eval {
    $tc2 = Test_Class2->boom(
        baz => 'testbaz',
        bam => 'testbam',
    );
};

ok($@ =~ /can\'t\s+autoinitialize/i, 'auto init');


package Test_Class3;
use base qw/ Class::Constructor /;

sub baz { $_[0]->{baz} = $_[1] if defined $_[1]; return $_[0]->{baz} }
sub bam { $_[0]->{bam} = $_[1] if defined $_[1]; return $_[0]->{bam} }

Test_Class3->mk_constructor(
    Auto_Init   => 'baz',
    Init_Method => '_init',
);

sub _init { 1 };

package main;

$tc = Test_Class3->new(
    baz => 'testbaz',
    bam => 'testbam',
);

is(ref $tc, 'Test_Class3', 'class 3 - object created');
ok(!defined $tc->bam,      'class 3 - initialization blocked');

ok($@ =~ /can\'t\s+autoinitialize/i, 'auto init');

package Test_Class4;
use base qw/ Class::Constructor /;

Test_Class4->mk_constructor(
    Init_Method => '_init_1',
    Init_Methods => [ '_init_2', '_init_3' ],
);

sub _init_1 {
    my $self = shift;
    $self->{_state} = 'init1';
}
sub _init_2 {
    my $self = shift;
    $self->{_state} .= '.init2';
}
sub _init_3 {
    my $self = shift;
    $self->{_state} .= '.init3';
}
sub get_state {
    my $self = shift;
    return $self->{_state};
}

package main;

$tc = Test_Class4->new;

is($tc->get_state,'init1.init2.init3', 'initialization methods');


package Subclass_Test;
use base qw/ Class::Constructor /;

sub baz { $_[0]->{baz} = $_[1] if defined $_[1]; return $_[0]->{baz} }
sub bam { $_[0]->{bam} = $_[1] if defined $_[1]; return $_[0]->{bam} }
sub type { $_[0]->{type} = $_[1] if defined $_[1]; return $_[0]->{type} }

Subclass_Test->mk_constructor(
    Name           => 'create',
    Subclass_Param => 'Type',
    Auto_Init      => [ qw/ baz bam type / ],
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
    baz  => 'testbaz',
    bam  => 'testbam',
);

$tc->set_bam;
$tc->set_baz;

is(ref $tc, 'Subclass_Test', 'non-subclassed object - object created');
is($tc->bam,'no', 'subclass - non-subclassed object method 1');
is($tc->baz,'no', 'subclass - non-subclassed object method 2');

$tc = Subclass_Test->create(
    baz  => 'testbaz',
    bam  => 'testbam',
    Type => 'Subclass1',
);

$tc->set_bam;
$tc->set_baz;

is(ref $tc, 'Subclass_Test::Subclass1', 'non-subclassed object - object created');
is($tc->bam,'yes', 'subclass - overridden method');
is($tc->baz,'no',  'subclass - non-overridden method');
is($tc->type,'Subclass1',  'subclass - Type available as method');




