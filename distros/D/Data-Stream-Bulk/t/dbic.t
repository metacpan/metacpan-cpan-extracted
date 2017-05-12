#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Test::Requires qw(
    DBIx::Class
    DBI
    DBD::SQLite
    Test::TempDir
);

use Test::TempDir 'temp_root';

our $schema;

BEGIN {
	plan skip_all => $@ unless eval {
		{
			package Schema::Foo;
			use base qw(DBIx::Class);

			__PACKAGE__->load_components(qw(Core));

			__PACKAGE__->table("foo");

			__PACKAGE__->add_columns(qw(id name));

			__PACKAGE__->set_primary_key("id");

			package Schema;
			use base qw(DBIx::Class::Schema);

			__PACKAGE__->load_classes(qw(Foo));

			1;
		}

		my $file = temp_root()->file("db");
		$schema = Schema->connect("dbi:SQLite:dbname=$file", undef, undef, { RaiseError => 1 } );
		$schema->storage->dbh->do("create table foo ( id integer primary key, name varchar )");
	};
}

use Data::Stream::Bulk::DBIC;

{
	my $d = Data::Stream::Bulk::DBIC->new( resultset => $schema->resultset("Foo") );

	ok( !$d->is_done, "not done" );

	is_deeply( [ $d->items ], [], "no items" );

	ok( $d->is_done, "now done" );
}

{
	$schema->resultset("Foo")->populate([
		{ name => "hello" },
		{ name => "goodbye" },
	]);

	my $d = Data::Stream::Bulk::DBIC->new( resultset => $schema->resultset("Foo") );

	ok( !$d->is_done, "not done" );
	is_deeply( [ map { $_->name } $d->items ], [ "hello" ], "one item" );
	ok( !$d->is_done, "not done" );
	is_deeply( [ map { $_->name } $d->items ], [ "goodbye" ], "one item" );
	ok( !$d->is_done, "not done" );
	is_deeply( [ $d->items ], [], "no items" );

	ok( $d->is_done, "now done" );
}

done_testing;
