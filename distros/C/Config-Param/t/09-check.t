#!perl

use Test::More tests => 5;
use Config::Param;
use strict;


my $errors;
my $a2ops = 0;
my $h2ops = 0;

sub even_check
{
	return ($_[2] % 2) != 0;
}


sub test_args
{
	my $errors;
	my $p = Config::Param::get
	(
		{ silenterr=>1, nofinals=>1, noexit=>1, nofile=>1 }
		,
		[
			{ long=>'scalar1', short=>'s', value=>0, help=>'a number'
			,	regex=> qr/^\d+$/, flags=>$Config::Param::nonempty }
		,	{ long=>'array1', short=>'a', value=>[], help=>'an array of non-numeric text bits'
			,	regex=> qr/^\D+$/, flags=>$Config::Param::nonempty }
		,	{ long=>'hash1', value=>{}, help=>'a hash with textual values, only signle words allowed'
			,	regex=> qr/^\w+$/, flags=>$Config::Param::nonempty }
		,	{ long=>'scalar2', short=>'S', value=>0, help=>'an even number'
			,	call=>\&even_check }
		,	{ long=>'array2', short=>'A', value=>[], help=>'an array of non-numeric text bits'
			,	regex=> qr/^\D+$/, call=>sub { ++$a2ops; return 0}
			,	flags=>$Config::Param::nonempty }
		,	{ long=>'hash2', value=>{}, help=>'a hash with textual values, only single words allowed'
			,	regex=> qr/^\w+$/, call=>sub { ++$h2ops; return 0}
			,	flags=>$Config::Param::append
			}
		],[
			@_
		], $errors
	);
	return @{$errors}+0;
}

# Too empty.
ok( 3 == test_args(), "defaults not enough" );
# Fine.
ok( 0 == test_args(qw(-A=ggf -a=sfgfsdg --hash1=blerg=4 --hash2=foo=bar --array2=bla))
,	'satisfying regexes' );
ok( (2 == $a2ops and 1 == $h2ops), 'ops counter' );
# No numeric value allowed.
ok( 1 == test_args(qw(-A=ggf -a=sfgfsdg --hash1=blerg=4 -a=6))
,	'unwanted numeric value' );
# Still only one error, as callback error shortcuts the regex check.
ok( 1 == test_args(qw(-A=ggf -a=sfgfsdg --hash1=blerg=4 -a=6 S=3))
,	'non-even number' );
