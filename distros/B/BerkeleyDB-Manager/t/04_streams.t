#!/usr/bin/perl

use strict;
use warnings;

use lib "t/lib";
use BerkeleyDB::Manager::Test 3.1, "no_plan";

use Test::More;
use Test::Moose;
use Test::TempDir;

use BerkeleyDB qw(DB_NEXT);

use ok 'BerkeleyDB::Manager';

{
	isa_ok( my $m = BerkeleyDB::Manager->new( home => temp_root(), create => 1 ), "BerkeleyDB::Manager" );

	isa_ok( $m->env, "BerkeleyDB::Env" );

	$m->txn_do(sub {
		my $db = $m->open_db("streams.db");

		my @entries = qw(foo bar gorch zot oink tra la di quxx baz moose elk bunny);

		$db->db_put($_ => $_) for @entries;

		foreach my $chunk_size ( undef, 100, 1, 2, 3 ) {
			{
				my $s = $m->cursor_stream( db => $db, chunk_size => $chunk_size, keys => 1 );

				does_ok( $s, "Data::Stream::Bulk" );

				ok( !$s->is_done, "not done" );

				my @all = $s->all;

				ok( $s->is_done, "now done" );

				is( scalar(@all), scalar(@entries), "stream size is like entries size" );

				is_deeply(
					[ sort @all ],
					[ sort @entries ],
					"got all keys",
				);
			}

			{
				my ( $key, $value ) = ( '', '' );

				my $s = $m->cursor_stream(
					chunk_size => $chunk_size,
					db       => $db,
					callback => sub {
						my ( $cursor, $ret ) = @_;

						if ( $cursor->c_get( $key, $value, DB_NEXT ) == 0 ) {
							push @$ret, $key;
							return 1;
						} else {
							return;
						}
					},
				);

				does_ok( $s, "Data::Stream::Bulk" );

				ok( !$s->is_done, "not done" );

				my @all = $s->all;

				ok( $s->is_done, "now done" );

				is( scalar(@all), scalar(@entries), "stream size is like entries size" );

				is_deeply(
					[ sort @all ],
					[ sort @entries ],
					"got all keys",
				);
			}
		}
	});
}

{
	isa_ok( my $m = BerkeleyDB::Manager->new( home => temp_root(), dup => 1, create => 1 ), "BerkeleyDB::Manager" );

	isa_ok( $m->env, "BerkeleyDB::Env" );

	$m->txn_do(sub {
		my $db = $m->open_db("streams_dup.db");

		my $i;
		my @entries = map { [ $_ => $i++ ] } qw(foo bar bar foo baz zot foo bar gorch foo foo moose);

		$db->db_put(@$_) for @entries;

		foreach my $chunk_size ( undef, 100, 1, 2, 3 ) {
			{
				my $s = $m->cursor_stream( db => $db, chunk_size => $chunk_size );

				does_ok( $s, "Data::Stream::Bulk" );

				ok( !$s->is_done, "not done" );

				my @all = $s->all;

				ok( $s->is_done, "now done" );

				is( scalar(@all), scalar(@entries), "stream size is like entries size" );

				is_deeply(
					[ sort { $a->[1] <=> $b->[1] } @all ],
					[ sort { $a->[1] <=> $b->[1] } @entries ],
					"got all pairs",
				);
			}

			{
				my $s = $m->cursor_stream( db => $db, chunk_size => $chunk_size, values => 1 );

				does_ok( $s, "Data::Stream::Bulk" );

				ok( !$s->is_done, "not done" );

				my @all = $s->all;

				ok( $s->is_done, "now done" );

				is( scalar(@all), scalar(@entries), "stream size is like entries size" );

				is_deeply(
					[ sort @all ],
					[ sort map { $_->[1] } @entries ],
					"got all pairs",
				);
			}

			{
				my ( $key, $value ) = ( '', '' );

				my $s = $m->cursor_stream(
					chunk_size => $chunk_size,
					db       => $db,
					callback => sub {
						my ( $cursor, $ret ) = @_;

						if ( $cursor->c_get( $key, $value, DB_NEXT ) == 0 ) {
							push @$ret, $key;
							return 1;
						} else {
							return;
						}
					},
				);

				does_ok( $s, "Data::Stream::Bulk" );

				ok( !$s->is_done, "not done" );

				my @all = $s->all;

				ok( $s->is_done, "now done" );

				is( scalar(@all), scalar(@entries), "stream size is like entries size" );

				is_deeply(
					[ sort @all ],
					[ sort map { $_->[0] } @entries ],
					"got all keys",
				);
			}

			{
				my @foos = grep { $_->[0] eq 'foo' } @entries;
				my $s = $m->dup_cursor_stream( db => $db, chunk_size => $chunk_size, key => "foo" );

				does_ok( $s, "Data::Stream::Bulk" );

				ok( !$s->is_done, "not done" );

				my @all = $s->all;

				ok( $s->is_done, "now done" );

				is( scalar(@all), scalar(@foos), "stream size is like foos size" );

				is_deeply(
					[ sort { $a->[1] <=> $b->[1] } @all ],
					[ sort { $a->[1] <=> $b->[1] } @foos ],
					"got all pairs of foo",
				);
			}

			{
				my $s = $m->dup_cursor_stream( db => $db, chunk_size => $chunk_size, key => "moose" );

				does_ok( $s, "Data::Stream::Bulk" );

				ok( !$s->is_done, "not done" );

				my @all = $s->all;

				ok( $s->is_done, "now done" );

				is( scalar(@all), 1, "stream size is one" );

				is_deeply(
					[ @all ],
					[ $entries[-1] ],
					"got pair",
				);
			}

			{
				my $s = $m->dup_cursor_stream( db => $db, chunk_size => $chunk_size, key => "not present" );

				does_ok( $s, "Data::Stream::Bulk" );

				my @all = $s->all;

				ok( $s->is_done, "now done" );

				is( scalar(@all), 0, "stream is empty" );
			}
		}
	});
}
