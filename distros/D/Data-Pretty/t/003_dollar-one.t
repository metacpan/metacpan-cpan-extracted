#!perl
use strict;
use warnings;
use lib './lib';
use vars qw( $DEBUG );
$DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
use Test::More tests => 6;

use Data::Pretty qw/dump/;
local $Data::Pretty::DEBUG = $DEBUG;

if ("abc" =~ /(.+)/) {
    is(dump($1), '"abc"', '"abc"');
    is(dump(\$1), '\"abc"', '\"abc"');
    is(dump([$1]), '["abc"]', '["abc"]');
}

if ("123" =~ /(.+)/) {
    is(dump($1), "123", "number");
    is(dump(\$1), '\123', 'scalar reference');
    is(dump([$1]), '[123]', '[123]');
}
