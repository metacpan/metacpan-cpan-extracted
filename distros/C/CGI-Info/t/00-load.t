#!perl -w

use warnings;
use strict;

use Test::Most tests => 2;

BEGIN {
	my $load_error;
	eval { require CGI::Info; CGI::Info->import() } or $load_error = $@;
	use_ok('CGI::Info') || BAIL_OUT("CGI::Info failed to load: $load_error");
}

require_ok('CGI::Info') || do {
	diag("Failed to require CGI::Info: $@");
	BAIL_OUT("CGI::Info failed to load: $@");
};

diag("Testing CGI::Info $CGI::Info::VERSION, Perl $], $^X");
