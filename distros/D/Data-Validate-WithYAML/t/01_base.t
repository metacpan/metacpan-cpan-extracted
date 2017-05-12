#!perl

use strict;
use Test::More tests => 2;

BEGIN {
    use_ok( 'Data::Validate::WithYAML' );
}

my @methods = qw(check validate fieldnames message errstr);
can_ok('Data::Validate::WithYAML',@methods);
