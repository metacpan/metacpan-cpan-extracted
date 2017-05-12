#!/usr/bin/perl -T

use Test::More tests => 3;

BEGIN {
	use_ok( 'Pod::Readme' );
}

ok( my $parser = Pod::Readme->new, 'Pod::Readme' );
ok( $parser->parse_from_file( 'lib/RFID/Biblio.pm' => 'README' ), 'README' );
