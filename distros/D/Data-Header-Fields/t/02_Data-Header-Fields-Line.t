#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';
#use Test::More tests => 10;
use Test::Differences;
use Test::Exception;

use IO::Any;

use FindBin qw($Bin);
use lib "$Bin/lib";

BEGIN {
	use_ok ( 'Data::Header::Fields' ) or exit;
}

exit main();

sub main {
	cmp_ok(
		Data::Header::Fields::Line->new("t1:123\n"),
		'eq',
		"t1:123\n",
		'new() with string'
	);
	cmp_ok(
		Data::Header::Fields::Line->new({'tight_folding' => 1, 'line' => 't2:321'}),
		'eq',
		"t2:321\n",
		'new() with {}'
	);
	
	# setting value will invalidate the original
	my $line1 = Data::Header::Fields::Line->new("t1:123\n");
	$line1->value('444');
	cmp_ok(
		$line1,
		'eq',
		"t1:444\n",
		'setting the value()'
	);
	
		
	return 0;
}

