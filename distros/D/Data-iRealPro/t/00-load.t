#!perl -T

my @modules;

BEGIN {
    @modules = 	( 'Data::iRealPro',
		  'Data::iRealPro::Song',
		  'Data::iRealPro::Playlist',
		  'Data::iRealPro::URI',
		  'Data::iRealPro::Output::Imager',
		  'Data::iRealPro::Output::HTML',
		  'Data::iRealPro::Output::JSON',
		  'Data::iRealPro::Output::Text',
		  'Data::iRealPro::Input::Text',
		  'Data::iRealPro::Input',
		  'Data::iRealPro::Output',
		);
}

use Test::More tests => scalar @modules;

BEGIN {
    use_ok($_) foreach @modules;
}

diag( "Testing Data::iRealPro $Data::iRealPro::VERSION, Perl $], $^X" );
