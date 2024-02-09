#!perl -wT

use strict;
use warnings;
use Test::Most;
use Test::Needs 'Test::Pod::Snippets';

if($ENV{'AUTHOR_TESTING'}) {
	my @modules = qw/ Database::Abstraction /;
	Test::Pod::Snippets->import();
	Test::Pod::Snippets->new()->runtest(module => $_, testgroup => 1) for @modules;

	done_testing();
} else {
	plan(skip_all => 'Author tests not required for installation');
}
