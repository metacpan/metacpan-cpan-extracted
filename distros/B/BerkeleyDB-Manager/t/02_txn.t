#!/usr/bin/perl

use strict;
use warnings;

use lib "t/lib";
use BerkeleyDB::Manager::Test 4.4, 'no_plan';

use Test::More;
use Test::Exception;
use Test::TempDir;

use ok "BerkeleyDB::Manager";

{
	isa_ok( my $m = BerkeleyDB::Manager->new( home => tempdir, create => 1 ), "BerkeleyDB::Manager" );

	isa_ok( $m->env, "BerkeleyDB::Env" );

	my $db;
	lives_ok { $db = $m->open_db( file => "foo.db" ) } "open with no home";

	isa_ok( $db, "BerkeleyDB::Btree" );

	is_deeply([ $m->all_open_dbs ], [ $db ], "open DBs" );

	my ( $commit, $rollback );

	throws_ok {
		$m->txn_do(
			sub {
				ok( $db->db_get("foo", my $v) != 0, "get failed" );

				sok( $db->db_put("foo", "bar"), "no error in put" );

				sok( $db->db_get("foo", $v), "no error in get" );
				is( $v, "bar", "'foo' key" );

				die "error";
			},
			rollback => sub { $rollback++ },
			commit   => sub { $commit++ },
		);
	} qr/error/, "dies in txn";

	ok( $rollback, "rollback callback triggered" );
	ok( !$commit, "commit callback not triggered" );

	{
		ok( $db->db_get("foo", my $v) != 0, "get failed (transaction aborted)" );
	}

	undef $commit;
	undef $rollback;

	lives_ok {
		$m->txn_do(
			sub {
				ok( $db->db_get("foo", my $v) != 0, "get failed" );

				sok( $db->db_put("foo", "bar"), "no error in put" );

				sok( $db->db_get("foo", $v), "no error in get" );
				is( $v, "bar", "'foo' key" );
			},
			rollback => sub { $rollback++ },
			commit   => sub { $commit++ },
		);
	} "no error in txn";

	ok( !$rollback, "rollback trigger not called" );
	ok( $commit, "commit trigger called" );

	{
		sok( $db->db_get("foo", my $v), "no error in get (transaction comitted)" );
		is( $v, "bar", "'foo' key" );
	}
}

{
	isa_ok( my $m = BerkeleyDB::Manager->new( home => tempdir, create => 1 ), "BerkeleyDB::Manager" );

	isa_ok( $m->env, "BerkeleyDB::Env" );

	my ( $first, $second ) = map { $m->open_db( file => $_ ) } qw(first.db second.db);

	is_deeply( [ sort $m->all_open_dbs ], [ sort $first, $second ], "open DBs" );

	throws_ok {
		$m->txn_do(sub {
			sok( $first->db_put("foo", "bar"), "no error in put" );
			sok( $second->db_put("gorch", "zot"), "no error in put" );

			die "error";
		});
	} qr/error/, "dies in txn";

	{
		ok( $first->db_get("foo", my $v) != 0, "get failed (transaction aborted)" );

		ok( $second->db_get("gorch", $v) != 0, "get failed (transaction aborted) in second db" );
	}

	lives_ok {
		$m->txn_do(sub {
			sok( $first->db_put("foo", "bar"), "no error in put" );
			sok( $second->db_put("gorch", "zot"), "no error in put" );
		});
	} "no error in txn";

	{
		sok( $first->db_get("foo", my $v), "get succeeded (transaction comitted)" );
		is( $v, "bar", "'foo' key" );

		sok( $second->db_get("gorch", $v), "get succeeded in second db" );
		is( $v, "zot", "'gorch' key" );
	}
}

{
	isa_ok( my $m = BerkeleyDB::Manager->new( home => tempdir, create => 1 ), "BerkeleyDB::Manager" );

	isa_ok( $m->env, "BerkeleyDB::Env" );

	my $db;
	lives_ok { $db = $m->open_db( file => "nested.db" ) } "open with no home";

	isa_ok( $db, "BerkeleyDB::Btree" );

	is_deeply([ $m->all_open_dbs ], [ $db ], "open DBs" );

	throws_ok {
		$m->txn_do(sub {
			ok( $db->db_get("foo", my $v) != 0, "get failed" );

			sok( $db->db_put("foo", "bar"), "no error in put" );

			$m->txn_do(sub {
				ok( $db->db_get("gorch", my $v) != 0, "get failed" );

				sok( $db->db_put("gorch", "bar"), "no error in put" );

				sok( $db->db_get("gorch", $v), "no error in get" );
				is( $v, "bar", "'gorch' key" );

				die "error";
			});
		})
	} qr/error/, "dies in inner txn";

	{
		ok( $db->db_get("foo", my $v) != 0, "get failed (transaction aborted)" );

		ok( $db->db_get("gorch", $v) != 0, "get failed (nested transaction aborted)" );
	}


	throws_ok {
		$m->txn_do(sub {
			ok( $db->db_get("foo", my $v) != 0, "get failed" );

			sok( $db->db_put("foo", "bar"), "no error in put" );

			$m->txn_do(sub {
				ok( $db->db_get("gorch", my $v) != 0, "get failed" );

				sok( $db->db_put("gorch", "bar"), "no error in put" );

				sok( $db->db_get("gorch", $v), "no error in get" );
				is( $v, "bar", "'gorch' key" );
			});

			die "error";
		})
	} qr/error/, "dies in outer txn";

	{
		ok( $db->db_get("foo", my $v) != 0, "get failed (transaction aborted)" );

		ok( $db->db_get("gorch", $v) != 0, "get failed (nested transaction aborted)" );
	}

	lives_ok {
		$m->txn_do(sub {
			ok( $db->db_get("foo", my $v) != 0, "get failed" );

			sok( $db->db_put("foo", "bar"), "no error in put" );

			$m->txn_do(sub {
				ok( $db->db_get("gorch", my $v) != 0, "get failed" );

				sok( $db->db_put("gorch", "bar"), "no error in put" );

				sok( $db->db_get("gorch", $v), "no error in get" );
				is( $v, "bar", "'gorch' key" );
			});
		});
	} "no error in txn";

	{
		sok( $db->db_get("foo", my $v), "no error in get (transaction comitted)" );
		is( $v, "bar", "'foo' key" );

		sok( $db->db_get("gorch", $v), "no error in get (transaction comitted)" );
		is( $v, "bar", "'foo' key" );
	}

	{
		ok( my $txn = $m->txn_begin, "parent transaction" );

			ok( $db->db_get("dancing", my $v) != 0, "get failed" );

			sok( $db->db_put("dancing", "bar"), "no error in put" );

			ok( my $ctxn = $m->txn_begin, "child transaction" );

				ok( $db->db_get("oi", $v) != 0, "get failed" );

				sok( $db->db_put("oi", "bar"), "no error in put" );

				sok( $db->db_get("oi", $v), "no error in get" );
				is( $v, "bar", "'oi' key" );

			ok( $m->txn_rollback, "rollback" );
			undef $ctxn;

			ok( $db->db_get("oi", $v) != 0, "get failed (rolled back)" );

			sok( $db->db_get("dancing", $v), "no error in get" );
			is( $v, "bar", "'dancing' key (only nested txn rolled back)" );

			ok( $ctxn = $m->txn_begin, "child transaction" );

				ok( $db->db_get("oi", $v) != 0, "get failed" );

				sok( $db->db_put("oi", "hippies"), "no error in put" );

				sok( $db->db_get("oi", $v), "no error in get" );
				is( $v, "hippies", "'oi' key" );

			ok( $m->txn_commit, "commit" );

		ok( $m->txn_commit, "commit" );


		sok( $db->db_get("dancing", $v), "no error in get" );
		is( $v, "bar", "'dancing' key" );

		sok( $db->db_get("oi", $v), "no error in get" );
		is( $v, "hippies", "'oi' key" );
	}
}

{
	isa_ok( my $m = BerkeleyDB::Manager->new( home => tempdir, transactions => 0, create => 1 ), "BerkeleyDB::Manager" );

	ok( !$m->transactions, "no txns" );

	my $db = $m->open_db( file => "naughty.db" );

	isa_ok( $db, "BerkeleyDB::Btree" );

	is_deeply([ $m->all_open_dbs ], [ $db ], "open DBs" );

	throws_ok { $m->txn_begin } qr/transaction.*not enabled/i, "can't begin transaction if transactions are disabled";

	sok( $db->db_put("bollocks", "moose"), "db_put outside of txn" );

	sok( $db->db_get("bollocks", my $v), "get ok" );
	is( $v, "moose", "value" );
}

{
	isa_ok( my $m = BerkeleyDB::Manager->new( home => tempdir, autocommit => 0, create => 1 ), "BerkeleyDB::Manager" );

	ok( $m->transactions, "txns enabled" );
	ok( !$m->autocommit, "autocommit disabled" );

	$m->txn_do(sub {
		my $db = $m->open_db("nice.db");

		isa_ok( $db, "BerkeleyDB::Btree" );

		is_deeply([ $m->all_open_dbs ], [ $db ], "open DBs" );

		sok( $db->db_put("bollocks", "moose"), "db_put outside of txn" );

		sok( $db->db_get("bollocks", my $v), "get ok" );
		is( $v, "moose", "value" );
	});

	ok( !$m->get_db("nice.db"), "no more db handle" );

	$m->txn_do(sub {
		ok( my $db = $m->open_db("nice.db"), "reopen" );

		sok( $db->db_get("bollocks", my $v), "get ok" );
		is( $v, "moose", "value" );
	});

	ok( !$m->get_db("nice.db"), "no more db handle" );

	{
		my $db = $m->open_db("nice.db");

		$m->txn_do(sub {
			ok( $db->db_put("bollocks", "orchid") != 0, "error in db_put with autocommit off, inside txn that was not opened in txn" );
		});

		sok( $db->db_put("bollocks", "elk"), "no error (no txn) db_put with autocommit off" );

		sok( $db->db_get("bollocks", my $v), "get ok" );
		is( $v, "elk", "new value" );

		$m->close_db("nice.db");
	}
}

SKIP: {
	skip "No MVCC support", 22 unless eval { BerkeleyDB::DB_TXN_SNAPSHOT; BerkeleyDB::DB_MULTIVERSION };
	isa_ok( my $m = BerkeleyDB::Manager->new( home => tempdir, create => 1, multiversion => 1 ), "BerkeleyDB::Manager" );

	isa_ok( $m->env, "BerkeleyDB::Env" );

	my $db;
	lives_ok { $db = $m->open_db( file => "mvcc.db" ) } "mvcc open";

	isa_ok( $db, "BerkeleyDB::Btree" );

	is_deeply([ $m->all_open_dbs ], [ $db ], "open DBs" );

	my ( $commit, $rollback );

	throws_ok {
		$m->txn_do(
			sub {
				ok( $db->db_get("foo", my $v) != 0, "get failed" );

				sok( $db->db_put("foo", "bar"), "no error in put" );

				sok( $db->db_get("foo", $v), "no error in get" );
				is( $v, "bar", "'foo' key" );

				die "error";
			},
			rollback => sub { $rollback++ },
			commit   => sub { $commit++ },
		);
	} qr/error/, "dies in txn";

	ok( $rollback, "rollback callback triggered" );
	ok( !$commit, "commit callback not triggered" );

	{
		ok( $db->db_get("foo", my $v) != 0, "get failed (transaction aborted)" );
	}

	undef $commit;
	undef $rollback;

	lives_ok {
		$m->txn_do(
			sub {
				ok( $db->db_get("foo", my $v) != 0, "get failed" );

				sok( $db->db_put("foo", "bar"), "no error in put" );

				sok( $db->db_get("foo", $v), "no error in get" );
				is( $v, "bar", "'foo' key" );
			},
			rollback => sub { $rollback++ },
			commit   => sub { $commit++ },
		);
	} "no error in txn";

	ok( !$rollback, "rollback trigger not called" );
	ok( $commit, "commit trigger called" );

	{
		sok( $db->db_get("foo", my $v), "no error in get (transaction comitted)" );
		is( $v, "bar", "'foo' key" );
	}
}

{
	isa_ok( my $m = BerkeleyDB::Manager->new( home => tempdir, create => 1, read_uncomitted => 1 ), "BerkeleyDB::Manager" );

	isa_ok( $m->env, "BerkeleyDB::Env" );

	my $db;
	lives_ok { $db = $m->open_db( file => "uncomitted.db" ) } "mvcc open";

	isa_ok( $db, "BerkeleyDB::Btree" );

	is_deeply([ $m->all_open_dbs ], [ $db ], "open DBs" );

	my ( $commit, $rollback );

	throws_ok {
		$m->txn_do(
			sub {
				ok( $db->db_get("foo", my $v) != 0, "get failed" );

				sok( $db->db_put("foo", "bar"), "no error in put" );

				sok( $db->db_get("foo", $v), "no error in get" );
				is( $v, "bar", "'foo' key" );

				die "error";
			},
			rollback => sub { $rollback++ },
			commit   => sub { $commit++ },
		);
	} qr/error/, "dies in txn";

	ok( $rollback, "rollback callback triggered" );
	ok( !$commit, "commit callback not triggered" );

	{
		ok( $db->db_get("foo", my $v) != 0, "get failed (transaction aborted)" );
	}

	undef $commit;
	undef $rollback;

	lives_ok {
		$m->txn_do(
			sub {
				ok( $db->db_get("foo", my $v) != 0, "get failed" );

				sok( $db->db_put("foo", "bar"), "no error in put" );

				sok( $db->db_get("foo", $v), "no error in get" );
				is( $v, "bar", "'foo' key" );
			},
			rollback => sub { $rollback++ },
			commit   => sub { $commit++ },
		);
	} "no error in txn";

	ok( !$rollback, "rollback trigger not called" );
	ok( $commit, "commit trigger called" );

	{
		sok( $db->db_get("foo", my $v), "no error in get (transaction comitted)" );
		is( $v, "bar", "'foo' key" );
	}
}

