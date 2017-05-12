#!/usr/bin/perl

use Test::More;
use Data::Dump qw(dump);

use lib 'lib';

BEGIN {
	use_ok( 'Biblio::RFID::Reader::librfid' );
}

ok( my $o = Biblio::RFID::Reader::librfid->new( tool => '/rest/cvs/librfid/utils/librfid-tool' ), 'new' );

my @tags = $o->inventory;
diag 'inventory = ', dump @tags;

my $old_afi;

foreach my $tag ( @tags ) {

	ok( my $blocks = $o->read_blocks( $tag ), "read_blocks $tag" );

	ok( my $afi = $o->read_afi( $tag ), "read_afi $tag" );

	cmp_ok( $afi, '==', -1, 'afi' );

}

done_testing;
