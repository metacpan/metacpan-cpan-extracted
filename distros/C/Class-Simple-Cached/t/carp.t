#!perl -wT

use strict;
use warnings;
use Class::Simple::Cached;
use CHI;
use Test::Most;
use Test::Needs 'Test::Carp';

CARP: {
	Test::Carp->import();

	does_croak_that_matches(sub {
		Class::Simple::Cached->new()
	}, qr/^Usage:\s/);

	does_croak_that_matches(sub {
		Class::Simple::Cached->new({ foo => 'bar' })
	}, qr/Cache must be\s/);

	done_testing();
}
