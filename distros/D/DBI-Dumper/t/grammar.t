#!/usr/bin/perl
# vim:ft=perl

use strict;
use warnings;

use DBI;
use DBI::Dumper;
use Test::More;
use File::Temp qw(tempfile);

my $sth = DummySTH->new;

my %test_controls = (
	q{
		options(rows=1000, export=1000)
		export data
		replace into file 'test.out'
		fields terminated by X'09'
		enclosed by '"' and '"'
		with header
		from
		select * from data
	} => sub { $_[1] ? 0 : 1 },
	q{
		options(foo)
		export data
		from
		select
	} => sub { $_[1] ? 1 : 0 },
	q{
		data from select
	} => sub { $_[1] ? 1 : 0 },
	q{
		export data replaec from select
	} => sub { $_[1] ? 1 : 0 },
	q{
		exprot data from select
	} => sub { $_[1] ? 1 : 0 },
	q{
		export data append into file 'test.out'
		from select
	} => sub { $_[1] ? 0 : 1 },
	q{
		export data
		fields terminated by
		enclosed by '"' and '"'
		from select
	} => sub { $_[1] ? 1 : 0 },
	q{
		-- comment
		export data 
		into file 'test with -- '
		--comment 
		from
		--comment
		select
	} => sub { $_[1] ? 0 : 1 },
);
plan tests => scalar keys %test_controls;

my $dumper = DBI::Dumper->new;
while(my($control_text, $testsub) = each %test_controls) {
	undef $::RD_ERRORS;
	undef $::RD_WARN;
	$dumper->control_text($control_text);
	eval { $dumper->prepare };
	ok($testsub->($dumper, $@)) || warn $control_text . $@;
}
0;

package DummySTH;
my $count = 0;
sub new { return bless {}, shift };
sub fetchrow_arrayref {
	return if $count++ > 10;
	return [qw(a b c)];
};

0;
