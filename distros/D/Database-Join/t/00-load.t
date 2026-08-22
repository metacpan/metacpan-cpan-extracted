#!perl -w

use warnings;
use strict;

use Test::Most tests => 2;

BEGIN {
	my $load_error;
	eval { require Database::Join; Database::Join->import() } or $load_error = $@;
	use_ok('Database::Join') || BAIL_OUT("Database::Join failed to load: $load_error");
}

require_ok('Database::Join') || do {
	diag("Failed to require Database::Join: $@");
	BAIL_OUT("Database::Join failed to load: $@");
};

diag("Testing Database::Join $Database::Join::VERSION, Perl $], $^X");
