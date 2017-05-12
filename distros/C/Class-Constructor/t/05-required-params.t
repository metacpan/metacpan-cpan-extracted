#!/usr/bin/perl

use strict;
use 5.005;
# use Cwd;

use File::Spec;
use lib File::Spec->join('t', 'lib');
use lib 'lib';

# use Test::More qw(no_plan);
use Test::More tests => 19;

BEGIN { use_ok('Class::Constructor'); }

package Test_Class;
use base qw/ Class::Constructor /;

sub foo { $_[0]->{foo} = $_[1] if defined $_[1]; return $_[0]->{foo} }
sub bar { $_[0]->{bar} = $_[1] if defined $_[1]; return $_[0]->{bar} }
sub baz { $_[0]->{baz} = $_[1] if defined $_[1]; return $_[0]->{baz} }

Test_Class->mk_constructor(
    Auto_Init => [ qw/ foo bar baz / ],
    Required_Params => [ qw/Bar bAz/ ],
);

package main;

my $tc;

eval {
    $tc = Test_Class->new(
        foo => 'testfoo',
    );
};

like($@, qr/required/i, 'exception on missing params');
unlike($@, qr/foo/i, 'no exception on passed param "foo"');
like($@, qr/bar/i, 'exception on missing param "bar"');
like($@, qr/baz/i, 'exception on missing param "baz"');
isnt(ref $tc, 'Test_Class', 'did not create object with missing params');

eval {
    $tc = Test_Class->new(
        foo => 'testfoo',
        bar => 'testbar',
    );
};

like($@, qr/required/i, 'exception for missing params');
isnt(ref $tc, 'Test_Class', 'did not create object with missing params');

like($@, qr/required/i, 'exception on missing params');
unlike($@, qr/foo/i, 'no exception on passed param "foo"');
unlike($@, qr/bar/i, 'no exception on passed param "bar"');
like($@, qr/baz/i, 'exception on missing param "baz"');
isnt(ref $tc, 'Test_Class', 'did not create object with missing params');

eval {
    $tc = Test_Class->new(
        bar => 'testbar',
        baz => 'testbaz',
    );
};

ok(!$@, 'no exception for missing params (1)');
is(ref $tc, 'Test_Class', 'created object: no params missing (1)');

undef $tc;
eval {
    $tc = Test_Class->new(
        bAR => 'testbar',
        baZ => 'testbaz',
    );
};

ok(!$@, 'no exception for missing params (2)');
is(ref $tc, 'Test_Class', 'created object: no params missing (2)');

is($tc->bar, 'testbar', 'method bar set');
is($tc->baz, 'testbaz', 'method baz set');

