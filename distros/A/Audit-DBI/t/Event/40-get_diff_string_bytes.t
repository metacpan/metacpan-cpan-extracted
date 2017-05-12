#!perl -T

use strict;
use warnings;

use Audit::DBI::Event;
use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 1;


can_ok(
	'Audit::DBI::Event',
	'get_diff_string_bytes',
);
