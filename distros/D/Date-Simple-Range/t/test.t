#!/usr/bin/perl -w

use Test::More 'tests' => 20;

	BEGIN { use_ok('Date::Simple::Range') };

	my $r = new Date::Simple::Range('2008-01-01');

	ok(defined $r,				'new returned a object');
	ok($r->isa('Date::Simple::Range'),	' and class is correct');
	ok(!$r,					" it's not complete");

	my $end = Date::Simple->new('2008-01-05');
	$r->end($end);
	
	ok($r,					" but can be completed");

	is($r->start, '2008-01-01',		'we can keep a start date');
	is($r->end, '2008-01-05',		'and the end date');

	$r >>= 4;
	$r <<= 2;
	
	is($r->start, '2008-01-03',		'and we can correctly shift them');
	is($r->end, '2008-01-07',		'back and forth');
	

	ok($r->duration,			'we have a duration');
	is($r->duration, 5 * 24 * 60 *60,		' w/ correct number of seconds');
	is($r->duration->days, 5,		' and days');
	is(scalar @$r, 5,			' even as a scalar reference');

	is("$r", '2008-01-03 - 2008-01-07',	'we can stringify correctly');

	my $r2 = $r->clone;
	
	ok($r2,					'we can be cloned');
	is($r->start, $r2->start,		' and still keep the date');
	is($r->end, $r2->end,			' (both of them)');
	
	my @a;
	my @b;
	my @expected = ('2008-01-03', '2008-01-04', '2008-01-05',
			'2008-01-06', '2008-01-07');
	
	while (<$r>) {
		push(@a, "$_");
	}

	while (<$r>) {
		push(@b, "$_");
	}

	is_deeply(\@a, \@expected,		'we can iterate with <>');
	is_deeply(\@b, \@expected,		' ...more than once!');
	is_deeply(\@{$r}, \@expected,		'and array dereferencing works fine');


__END__;


#!/usr/bin/perl -w

use ExtUtils::testlib;

use Time::Duration;
use Date::Simple::Range;

	my $end = new Date::Simple('2008-01-05');
	my $range = new Date::Simple::Range('2008-01-01', $end)
		or die;

	my $pre = $range->clone;

	print $range, "\n";

	$range >>= 2;


	print $pre, "\n";
	print $range, "\n";

	print duration($range->duration), "\n";
	print $range->duration->days, " days\n";

	print "array dereference test:\n";
	for (@$range) {
		print $_, "\n";
	}

	print "iterator test:\n";
	while (<$range>) {
		print $_, "\n";
	}

	print "iterator test (again):\n";
	while (<$range>) {
		print $_, "\n";
	}

