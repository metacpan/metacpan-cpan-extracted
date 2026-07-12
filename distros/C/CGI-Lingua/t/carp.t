#!perl -wT

use strict;
use warnings;
use Test::Most tests => 3;

BEGIN {
	use_ok('CGI::Lingua');
}

# croak is now imported into CGI::Lingua at compile time (use Carp qw(croak carp)),
# so Test::Carp's Carp::croak interception misses it. Use throws_ok instead,
# which catches any exception via eval regardless of which package owns the symbol.
throws_ok(
	sub { CGI::Lingua->new({ logger => sub { } }) },
	qr/You must give a list of supported languages/,
	'new() without supported list throws expected message (hashref form)'
);
throws_ok(
	sub { CGI::Lingua->new(supported => undef) },
	qr/You must give a list of supported languages/,
	'new() with undef supported throws expected message (flat form)'
);
