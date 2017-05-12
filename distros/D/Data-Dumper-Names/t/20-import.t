#!/usr/bin/perl
# '$Id: 20import.t,v 1.1 2004/08/03 04:48:39 ovid Exp $';
use warnings;
use strict;
#use Test::More tests => 2;
use Test::More qw/no_plan/;

# never forget CC

my $CLASS;
use Data::Dumper::Names ();

ok ! __PACKAGE__->can('Dumper'),
    'Dumper() should not be exported unless we ask for it';

my $scalar = 'Ovid';
my @array  = qw/Data Dumper Names Rocks!/;

my $expected = Data::Dumper->Dump(
    [$scalar, \@array],
    [qw/$scalar *array/]
);

is(Data::Dumper::Names::Dumper($scalar, \@array), $expected,
    '... but it should still work correctly');
