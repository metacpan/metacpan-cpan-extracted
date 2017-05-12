#!perl

use Test::More tests => 5;

BEGIN {
	use_ok( 'DateTime::Indic::Utils' );
    diag( "Testing DateTime::Indic::Utils $DateTime::Indic::Utils::VERSION" );
	use_ok( 'DateTime::Indic::Chandramana' );
    diag( "Testing DateTime::Indic::Chandramana $DateTime::Indic::Chandramana::VERSION" );
	use_ok( 'DateTime::Calendar::HalariSamvata' );
    diag( "Testing DateTime::Calendar::HalariSamvata $DateTime::Calendar::HalariSamvata::VERSION" );
	use_ok( 'DateTime::Calendar::VikramaSamvata::Gujarati' );
    diag( "Testing DateTime::Calendar::VikramaSamvata::Gujarati $DateTime::Calendar::VikramaSamvata::Gujarati::VERSION" );
	use_ok( 'DateTime::Calendar::ShalivahanaShaka::Southern' );
    diag( "Testing DateTime::Calendar::ShalivahanaShaka::Southern $DateTime::Calendar::ShalivahanaShaka::Southern::VERSION" );
}

diag( "Perl $], $^X" );
