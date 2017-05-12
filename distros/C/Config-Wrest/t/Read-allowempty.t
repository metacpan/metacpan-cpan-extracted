#!/usr/local/bin/perl

#
# Test the AllowEmptyValues feature
# $Id: Read-allowempty.t,v 1.9 2006/07/06 14:01:56 mattheww Exp $

use strict;
use Getopt::Std;
use lib("./lib","../lib");
use Config::Wrest;
use Test::Assertions('test');

use vars qw($opt_t $opt_T);

getopts('tT');
if($opt_t) {
	require Log::Trace;
	import Log::Trace qw(print);
}
if($opt_T) {
	require Log::Trace;
	import Log::Trace qw(print), { Deep => 1 };
}

my $whingetrap = "";

plan tests;

my $data = 
"badger stripey
snake hiss
mushroom
";

##############################################################################
my $cr = new Config::Wrest( Strict => 0, AllowEmptyValues => 0 );
my $vardata;
{
	local $SIG{__WARN__} = sub { $whingetrap .= join "", @_ };
	$vardata = $cr->deserialize($data);
};
ASSERT($whingetrap =~ /only valid in a list/, "blank line produced warning");
ASSERT(! defined $vardata->{"mushroom"}, "blank line produced no defined data");
ASSERT(! $vardata->{"mushroom"}, "blank line produced no data");

my $str = "";
$whingetrap = "";
{
	local $SIG{__WARN__} = sub { $whingetrap .= join "", @_ };
	$str = $cr->serialize({
		colour => 'red',
		wings => '',
	});
};
ASSERT($whingetrap =~ /not writing an empty value/, "not writing blank value");
ASSERT(scalar($str =~ /colour/), "a line for 'colour'");
ASSERT(scalar($str !~ /wings/), "no line for 'wings'");

$str = "";
$whingetrap = "";
{
	local $SIG{__WARN__} = sub { $whingetrap .= join "", @_ };
	$str = $cr->serialize({
		colour => [
			'taupe',
			'',
			'greige',
		],
	});
};
ASSERT($whingetrap =~ /not writing an empty value/, "not writing blank value");
ASSERT(scalar($str =~ /'taupe'\n\t'greige'/), "2 lines");

##############################################################################
$cr = new Config::Wrest( AllowEmptyValues => 0 );
eval {
	$cr->deserialize($data);
};
ASSERT($@ =~ /only valid in a list/, "blank line error (Strict)");

eval {
	$cr->serialize({
		colour => 'red',
		wings => '',
	});
};
ASSERT($@ =~ /not writing an empty value/, "not writing blank value error (Strict)");

eval {
	$cr->serialize({
		colour => [
			'taupe',
			'',
			'greige',
		],
	});
};
ASSERT($@ =~ /not writing an empty value/, "not writing blank value error (Strict)");


##############################################################################
$whingetrap = "";
$cr = new Config::Wrest( AllowEmptyValues => 1 );
undef $vardata;
{
	local $SIG{__WARN__} = sub { $whingetrap .= join "", @_ };
	$vardata = $cr->deserialize($data);
};
ASSERT(!$whingetrap, "blank line produced no warning with AllowEmptyValues switched on");
ASSERT(defined $vardata->{"mushroom"}, "blank line produced defined value");
ASSERT(!length $vardata->{"mushroom"}, "blank line produced empty value");

$str = "";
$whingetrap = "";
{
	local $SIG{__WARN__} = sub { $whingetrap .= join "", @_ };
	$str = $cr->serialize({
		colour => 'red',
		wings => '',
	});
};
ASSERT(! $whingetrap, "no warning");
ASSERT(scalar($str =~ /colour/), "a line for 'colour'");
ASSERT(scalar($str =~ /wings/), "a line for 'wings'");

$str = "";
$whingetrap = "";
{
	local $SIG{__WARN__} = sub { $whingetrap .= join "", @_ };
	$str = $cr->serialize({
		colour => [
			'taupe',
			'',
			'greige',
		],
	});
};
ASSERT(! $whingetrap, "no warning");
ASSERT(scalar($str =~ /'taupe'\n\t''\n\t'greige'/), "3 lines");
