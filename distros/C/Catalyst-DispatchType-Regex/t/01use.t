use Test::More;
# This kludge is necessary to avoid failing due to circular dependencies
# with Catalyst-Runtime. Not ideal, but until we remove CDR from
# Catalyst-Runtime prereqs, this is necessary to avoid Catalyst-Runtime build
# failing.
BEGIN {
    plan skip_all => 'Catalyst::Runtime required'
        unless eval { require Catalyst };
    plan skip_all => 'Test requires Catalyst::Runtime >= 5.90030' unless $Catalyst::VERSION >= 5.90030;
    plan tests => 1;
}

use_ok( 'Catalyst::DispatchType::Regex' );

diag( "Testing Catalyst::DispatchType::Regex $Catalyst::DispatchType::Regex::VERSION" );
