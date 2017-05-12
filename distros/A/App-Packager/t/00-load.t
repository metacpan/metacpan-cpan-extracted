#! perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'App::Packager' );
}

diag( "Testing App::Packager $App::Packager::VERSION, Perl $], $^X" );

if ( eval { require Cava::Packager } ) {
    diag( "Fallback available: Cava::Packager version $Cava::Packager::VERSION" );
}
else {
    diag( "No fallback (Cava::Packager not found)" );
}

