use Test::More tests => 12;

BEGIN {
use_ok( 'BioX::CLPM' );
use_ok( 'BioX::CLPM::Engine' );
use_ok( 'BioX::CLPM::Peaks' );
use_ok( 'BioX::CLPM::Linker' );
use_ok( 'BioX::CLPM::Enzyme' );
use_ok( 'BioX::CLPM::Amino' );
use_ok( 'BioX::CLPM::Sequence' );
use_ok( 'BioX::CLPM::Fragments' );
use_ok( 'BioX::CLPM::Fragments::Simple' );
use_ok( 'BioX::CLPM::Fragments::Linked' );
use_ok( 'BioX::CLPM::Matches' );
use_ok( 'BioX::CLPM::Base' );
}

diag( "Testing BioX::CLPM $BioX::CLPM::VERSION" );
