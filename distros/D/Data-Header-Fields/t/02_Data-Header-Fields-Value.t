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
	my $value = Data::Header::Fields::Value->new('abc');
	is($value.'x', 'abcx', 'as_string() overloaded');
	
	my $text = '';
	my $text_fh = IO::Any->write(\$text);
	print $text_fh $value;
	is($text, 'abc', 'as_string() overloaded');

	my $two_lines = Data::Header::Fields::Value->new("abc\n 123");
	is($two_lines, 'abc 123', 'as_string() overloaded with two lines');
	
	my $three_lines = Data::Header::Fields::Value->new("abc\n 123\n  321\n");
	is($three_lines, "abc 123  321", 'as_string() overloaded with three lines');
	
	return 0;
}

