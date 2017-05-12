#!/usr/bin/perl -W

use strict;
use warnings;
use Data::Page;
use Data::Page::Pageset;
use Test::More tests => 1;
use Test::Exception;
use Data::Dumper;
# total_entries, entries_per_page, current_page, pages_per_set, max_pagesets,
# [1024,25,13,6,3]
my @testset = (
	[1024,25,13,6,3],
	[1024,25,13,6],
);
local $, = ',';

map {
	msg( "-" x 30 ."\n" );
	my ( $total_entries, $entries_per_page, $current_page, $pages_per_set, $max_pagesets ) = @$_;
	msg( "total_entries: $total_entries \n" );
	msg( "entries_per_page: $entries_per_page \n" );
	msg( "current_page: $current_page \n" );
	msg( "pages_per_set: $pages_per_set \n" );
	$max_pagesets
		? msg( "max_pagesets: $max_pagesets \n" )
		: msg( "max_pagesets: [undef] \n" );

	my $page = Data::Page->new($total_entries, $entries_per_page, $current_page);
	my $pageset = Data::Page::Pageset->new( $page, { pages_per_set => $pages_per_set, max_pagesets => $max_pagesets } );

	msg( "Output: " );
	foreach my $chunk ( $pageset->total_pagesets ){
		if ( $chunk->is_current ){
			map { msg( "$_ " ) } ( $chunk->first .. $chunk->last );
		}else{
			msg( "$chunk " );
		}
	}
	msg( "\n" );
} @testset;
msg( "-" x 30 ."\n" );
ok( 1 > 0, 'ok' );

sub msg { print STDERR shift };