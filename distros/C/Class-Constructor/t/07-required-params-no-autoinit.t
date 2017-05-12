#!/usr/bin/perl

use strict;
use 5.005;
# use Cwd;

use File::Spec;
use lib File::Spec->join('t', 'lib');
use lib 'lib';

# use Test::More qw(no_plan);
use Test::More tests => 5;

BEGIN { use_ok('Class::Constructor'); }

package Test_Class;
use base qw/ Class::Constructor /;

sub foo { $_[0]->{foo} = $_[1] if defined $_[1]; return $_[0]->{foo} }
sub bar { $_[0]->{bar} = $_[1] if defined $_[1]; return $_[0]->{bar} }
sub baz { $_[0]->{baz} = $_[1] if defined $_[1]; return $_[0]->{baz} }

Test_Class->mk_constructor(
    Auto_Init => [ qw/ foo baz / ],
    Required_Params => [ qw/Bar bAz/ ],
);

package main;

my $tc;

undef $tc;
eval {
    $tc = Test_Class->new(
        bAR => 'testbar',
        baZ => 'testbaz',
    );
};

ok(!$@, 'no exception for missing params (2) ' . $@);
is(ref $tc, 'Test_Class', 'created object: no params missing (2)');

is($tc->bar, 'testbar', 'method bar set');
is($tc->baz, 'testbaz', 'method baz set');

