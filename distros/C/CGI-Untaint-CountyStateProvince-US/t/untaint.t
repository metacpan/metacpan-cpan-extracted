#!perl -w

use strict;
use warnings;
use Test::More;

eval 'use Test::CGI::Untaint';

if($@) {
	plan skip_all => 'Test::CGI::Untaint required for testing extraction handler';
} else {
	plan tests => 3;

	use_ok('CGI::Untaint::CountyStateProvince::US');

	is_extractable('California', 'CA', 'CountyStateProvince');
	unextractable('Foo', 'CountyStateProvince');
}
