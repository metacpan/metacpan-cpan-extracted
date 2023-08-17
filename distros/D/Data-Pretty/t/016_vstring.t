#!perl -w

BEGIN {
    if ($] < 5.010) {
	print "1..0 # Skipped: perl-5.10 required\n";
	exit;
    }
}

use strict;
use warnings;
use lib './lib';
use vars qw( $DEBUG );
$DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
use Test::More;
plan tests => 9;

use Data::Pretty 'dump';
local $Data::Pretty::DEBUG = $DEBUG;

is(dump(v10), q{v10}, 'version');
is(dump(v5.10.1), q{v5.10.1}, 'version dotted');
is(dump(5.10.1), q{v5.10.1}, 'version dotted');
is(dump(500.400.300.200.100), q{v500.400.300.200.100}, 'version dotted');

is(dump(\5.10.1), q{\v5.10.1}, 'version dotted escaped');
is(dump(\v10), q{\v10}, 'version dotted escaped');
is(dump(\\v10), q{\\\\v10}, 'version dotted escaped');
is(dump([v10, v20, v30]), q{[v10, v20, v30]}, 'array of versions dotted');
is(dump({ version => v6.0.0 }), q({ version => v6.0.0 }), 'hash of version dotted');
