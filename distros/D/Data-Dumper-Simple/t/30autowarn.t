#!/usr/bin/perl
# '$Id: 30autowarn.t,v 1.1 2004/08/03 04:48:52 ovid Exp $';
use warnings;
use strict;
use Test::More tests => 3;

my $warning;
$SIG{__WARN__} = sub { $warning = join '' => @_ };

my $carp;
sub carp { $carp = join '' => @_ };

my $CLASS;
BEGIN
{
    chdir 't' if -d 't';
    unshift @INC => '../lib';
    $CLASS = 'Data::Dumper::Simple';
    use_ok($CLASS, autowarn => 1) or die;
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

Dumper($scalar, @array, %hash);
is($warning, $expected, 'Dumper should be able to autowarn');

no Data::Dumper::Simple;
use Data::Dumper::Simple autowarn => 'carp';
Dumper($scalar, @array, %hash);
is($carp, $expected, 
    '... even if we use a different function name');
