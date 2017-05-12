#!/usr/bin/perl -w

# $Id: LazyMethod.t,v 1.2 2004/03/27 13:40:17 cwg Exp $

use strict;
use Test::More tests => 5;

use constant DEBUG => 0;

BEGIN { use_ok( 'DBIx::LazyMethod' ); }

require_ok( 'DBIx::LazyMethod' );
require_ok( 'DBI' );

        my %methods = (
               create_people_table => {
                       sql => "CREATE TABLE people (name VARCHAR(255), id INT)",
                       args => [ qw() ],
                       ret => WANT_RETURN_VALUE,
               },
               drop_people_table => {
                       sql => "DROP TABLE people",
                       args => [ qw() ],
                       ret => WANT_RETURN_VALUE,
               },
               create_people_entry => {
                       sql => "INSERT INTO people (name,id) VALUES (?,?)",
                       args => [ qw(name id) ],
                       ret => WANT_RETURN_VALUE,
               },
               set_people_name_by_id => {
                       sql => "UPDATE people SET name = ? WHERE id = ?",
                       args => [ qw(name id) ],
                       ret => WANT_RETURN_VALUE,
               },
               get_people_id_by_name => {
                       sql => "SELECT id FROM people WHERE name = ?",
                       args => [ qw(name) ],
                       ret => WANT_ARRAY,
               },
               get_people_entry_by_id => {
                       sql => "SELECT * FROM people WHERE id = ?",
                       args => [ qw(id) ],
                       ret => WANT_HASHREF,
               },
               get_all_people_entries => {
                       sql => "SELECT * FROM people",
                       args => [ qw() ],
                       ret => WANT_ARRAY_HASHREF,
               },
               get_people_count => {
                       sql => "SELECT COUNT(*) FROM people",
                       args => [ qw() ],
                       ret => WANT_ARRAY,
               },
               delete_people_entry_by_id => {
                       sql => "DELETE FROM people WHERE id = ?",
                       args => [ qw(id) ],
                       ret => WANT_RETURN_VALUE,
               },
        );

        my $db = DBIx::LazyMethod->new(
#		data_source  => "DBI:Proxy:hostname=192.168.1.1;port=7015;dsn=DBI:Oracle:PERSONS",
		data_source => "DBI:ExampleP:",
		user => 'csv',
		pass => 'csv',
		attr => { 'RaiseError' => 1, 'AutoCommit' => 1 },
		methods => \%methods,
		);

	is(ref $db, 'DBIx::LazyMethod', 'Test the constructed object');

        if ($db->is_error) { die $db->{errormessage}; }
	is($db->is_error, 0, 'Test new good instance');

	undef $db;
