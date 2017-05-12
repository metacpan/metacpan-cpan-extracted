use strict;

use Test::More;

# Work around buffering that can show diags out of order
Test::More->builder->failure_output(*STDOUT) if $ENV{HARNESS_VERBOSE};

plan tests => 1;

eval { require CPAN::Test::Dummy::Perl5::Make::PerlReq::Fail };

ok( $@, "modules fails to load (as expected)" );

