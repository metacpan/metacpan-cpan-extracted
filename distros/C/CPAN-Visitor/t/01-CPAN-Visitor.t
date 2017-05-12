use strict;
use warnings;

use Test::More;

# Work around buffering that can show diags out of order
Test::More->builder->failure_output(*STDOUT) if $ENV{HARNESS_VERBOSE};

plan tests => 1;

require_ok( 'CPAN::Visitor' );

