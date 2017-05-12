#!/usr/bin/perl
# '$Id: 40noparens.t,v 1.1 2005/05/20 01:36:47 ovid Exp $';
use warnings;
use strict;
use Test::More tests => 6;

my $CLASS;
BEGIN
{
    chdir 't' if -d 't';
    unshift @INC => '../lib';
    $CLASS = 'Data::Dumper::Simple';
    use_ok($CLASS) or die;
}

my $scalar = 'Ovid';
my @array  = qw/Data Dumper Simple Rocks!/;
my %hash   = (
    at => 'least',
    I  => 'hope',
    it => 'does',
);

my $expected = Data::Dumper->Dump(
    [$scalar, \@array, \%hash],
    [qw/$scalar *array *hash/]
);

my $got = Dumper $scalar, @array, %hash;

is($got, $expected, 'Having no parens is allowed');

$got = Dumper
    $scalar,
    @array,
    %hash;

is($got, $expected, '... even split among several lines');

$got = Dumper
    $scalar =>
    @array =>
    %hash
    ;

is($got, $expected, '... or using big arrows, or whitespace before the semicolon');

{
    $got = Dumper
	$scalar,
	@array,
	%hash
}

is($got, $expected, '... or at the end of a block (no semicolon)');

$got = Dumper
    $hash{I},
    $array[3];

$expected = Data::Dumper->Dump(
    [$hash{I}, $array[3]],
    [qw/$hash{I} $array[3]/]
);

is($got, $expected, '... or with aggregate elements');
