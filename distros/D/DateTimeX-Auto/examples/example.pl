#!/usr/bin/perl

use lib "lib";
use DateTimeX::Auto ':auto';
use Data::Dumper;

my %d;

$d{'d'} = '2010-01-01';

$d{'dt'} = '2010-01-01T12:00:00';

$d{'dt2'} = '2010-01-01T12:00:00.12345678901234567890';

{
	no DateTimeX::Auto;
	$d{'str'} = '2010-01-01';
}

$d{'d2'} = '2011-01-01';

{
	no DateTimeX::Auto;
	DateTimeX::Auto->import('d dt');
	$d{'func'} = d("2008-01-01");
	$d{'func2'} = dt("2008-01-01");
}

foreach my $k (sort keys %d)
{
	my $v = $d{ $k };
	print "$k = $v ".ref($v);
	print "\n";
}

print '2000-01-01' + 'P2.5D', "\n";

print ref('2000-01-01')."\n";