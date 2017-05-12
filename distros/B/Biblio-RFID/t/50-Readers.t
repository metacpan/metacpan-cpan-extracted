#!/usr/bin/perl

use Test::More; # tests => 3;
use Data::Dump qw(dump);

use lib 'lib';

BEGIN {
	use_ok( 'Biblio::RFID::Reader' );
}

ok( my $o = Biblio::RFID::Reader->new( shift @ARGV ), 'new' );

ok( my $tags = [ $o->tags ], 'tags' );
diag 'tags: ', dump( $tags );

done_testing();

__END__

ok( my @tags = $o->inventory, 'inventory' );
diag dump @tags;

my $old_afi;

foreach my $tag ( @tags ) {

	ok( my $blocks = $o->read_blocks( $tag ), "read_blocks $tag" );

	ok( my $afi = $o->read_afi( $tag ), "read_afi $tag" );

	ok( $o->write_blocks( $tag, $blocks->{$tag} ), "write_blocks $tag" );

	my $new_afi = "\x42";

	ok( $o->write_afi( $tag, $new_afi ), sprintf( "write_afi %s %x", $tag, $new_afi ) );

	cmp_ok( $o->read_afi( $tag ), 'eq', $new_afi, 'AFI check' );

	ok( $o->write_afi( $tag, $afi ), sprintf( "write_afi %s %x", $tag, $afi ) );

}

ok( my $visible = $o->scan, 'scan' );
diag dump $visible;

done_testing();
