#!/usr/bin/perl
# '$Id: 10dump.t,v 1.6 2004/08/03 04:52:28 ovid Exp $';
use warnings;
use strict;

# many fewer tests required than for Data::Dumper::Simple
# because this is not a source filter
use Test::More 'no_plan'; # tests => 8;
#use Test::More qw/no_plan/;

my $CLASS;

BEGIN {
    chdir 't' if -d 't';
    unshift @INC => '../lib';
    $CLASS = 'Data::Dumper::Names';
    use_ok($CLASS) or die;
}

my $scalar = 'Ovid';
my @array  = qw/Data Dumper Simple Rocks!/;
my %hash   = (
    at => 'least',
    I  => 'hope',
    it => 'does',
);

is(
    Dumper($scalar),
    "\$scalar = 'Ovid';\n",
    '... and dumped variables are named'
);
is(
    Dumper( \$scalar ),
    "\$scalar = \\'Ovid';\n",
    '... and dumping a scalar as a reference should work'
);

my $expected = Data::Dumper->Dump( [ @array ], [qw/VAR1 VAR2 VAR3 VAR4/] );
is( Dumper(@array), $expected, '... flattened data structures return VARs' );

my $array = \@array;
$expected = Data::Dumper->Dump( [ $array ], ['*array'] );
is( Dumper( \@array ),
    $expected, '... but it will still "flatten" a reference' );

$expected =
  Data::Dumper->Dump( [ $scalar, \@array, \%hash ],
    [qw/$scalar *array *hash/] );

is( Dumper( $scalar, \@array, \%hash ),
    $expected, '... or have a list of them' );

my $fool = 'Ovid';

sub test_scope {
    $expected = Data::Dumper->Dump([$fool],['*fool']);
    is Dumper($fool), $expected,
        'Dumper should get the name so long as it is in scope';
}

test_scope;

my $foo = \@array;
$expected = Data::Dumper->Dump( [ $foo, \@array ], [qw/$foo *array/] );
is Dumper( $foo, \@array ), $expected,
    'References should maintain their correct names';

#
# Testing $UpLevel
#

{
    my $idiot = 'Ovidius';
    local $Data::Dumper::Names::UpLevel = 2;
    is test_uplevel($idiot), "\$idiot = 'Ovidius';\n",
        '$UpLevel should adjust where we look for variables';
}

is Dumper( $foo, \@array ), $expected,
    '... but returning to a new scope should still work';

sub test_uplevel {
    return Dumper(@_);
}

