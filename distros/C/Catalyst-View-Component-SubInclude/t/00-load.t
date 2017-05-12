#!perl

use Test::More;

BEGIN {
	use_ok( 'Catalyst::View::Component::SubInclude' );
    use_ok( 'Catalyst::View::Component::SubInclude::SubRequest' );
    use_ok( 'Catalyst::View::Component::SubInclude::ESI' );
    use_ok( 'Catalyst::View::Component::SubInclude::SSI' );
    use_ok( 'Catalyst::View::Component::SubInclude::Visit' );
    use_ok( 'Catalyst::View::Component::SubInclude::HTTP' );
}

diag( "Testing Catalyst::View::Component::SubInclude $Catalyst::View::Component::SubInclude::VERSION, Perl $], $^X" );

done_testing;
