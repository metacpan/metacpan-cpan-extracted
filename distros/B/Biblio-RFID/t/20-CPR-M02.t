#!/usr/bin/perl

use Test::More;
use Data::Dump qw(dump);

use lib 'lib';

BEGIN {
	use_ok( 'Biblio::RFID::Reader::CPRM02' );
}

ok( my $o = Biblio::RFID::Reader::CPRM02->new( device => '/dev/ttyUSB0' ), 'new' );

my @tags = $o->inventory;
diag 'inventory ',dump(@tags);

foreach my $tag ( @tags ) {

	ok( my $blocks = $o->read_blocks( $tag ), "read_blocks $tag" );

	my $pattern = "\x00\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0A\x0B\x0C\x0D\x0E\x0F";
	ok( $o->write_blocks( $tag, $pattern ), "write_blocks $tag" );
	
	$pattern = "0123456789ABCDEF.....";
	ok( $o->write_blocks( $tag, $pattern ), "write_blocks $tag" );

#	ok( $o->write_blocks( $tag, $blocks->{$tag} ), "write_blocks $tag" );

}

done_testing;
