#!/usr/bin/perl
# '$Id: 20import.t,v 1.1 2004/08/03 04:48:39 ovid Exp $';
use warnings;
use strict;
use Test::More tests => 2;

# never forget CC

my $CLASS;
BEGIN
{
    chdir 't' if -d 't';
    unshift @INC => '../lib';
    $CLASS = 'Data::Dumper::Simple';
    use_ok($CLASS, as => 'frobnitz') or die;
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

is(frobnitz($scalar, @array, %hash), $expected,
    'Using a different subroutine name for "Dumper" should work as expected');
