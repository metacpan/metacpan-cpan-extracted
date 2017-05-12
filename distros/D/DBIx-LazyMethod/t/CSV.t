#!/usr/bin/perl -w

# $Id: CSV.t,v 1.2 2004/03/27 13:40:17 cwg Exp $

use strict;
#use lib qw(lib ../lib);
use Test::More;
use DBI;

my $DBD = 'CSV'; #DBD to test
my @driver_names = DBI->available_drivers;

unless (grep { $_ eq $DBD } @driver_names) {
	plan skip_all => "Test irrelevant unless $DBD DBD is installed";
} else {
	plan tests => 15;
}

use constant DEBUG => 0;

BEGIN { use_ok( 'DBIx::LazyMethod' ); }

require_ok( 'DBIx::LazyMethod' );

        my %methods = (
               create_people_table => {
                       sql => "CREATE TABLE people (id int NOT NULL PRIMARY KEY, name VARCHAR(255), alias INT)",
                       args => [ qw() ],
                       ret => WANT_RETURN_VALUE,
               },
               drop_people_table => {
                       sql => "DROP TABLE people",
                       args => [ qw() ],
                       ret => WANT_RETURN_VALUE,
               },
               create_people_entry => {
                       sql => "INSERT INTO people (name,alias) VALUES (?,?)",
                       args => [ qw(name alias) ],
                       ret => WANT_RETURN_VALUE,
               },
               set_people_name_by_alias => {
                       sql => "UPDATE people SET name = ? WHERE alias = ?",
                       args => [ qw(name alias) ],
                       ret => WANT_RETURN_VALUE,
               },
               get_people_alias_by_name => {
                       sql => "SELECT alias FROM people WHERE name = ?",
                       args => [ qw(name) ],
                       ret => WANT_ARRAY,
               },
               get_people_entry_by_alias => {
                       sql => "SELECT * FROM people WHERE alias = ?",
                       args => [ qw(alias) ],
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
               delete_people_entry_by_alias => {
                       sql => "DELETE FROM people WHERE alias = ?",
                       args => [ qw(alias) ],
                       ret => WANT_RETURN_VALUE,
               },
        );

        my $db = DBIx::LazyMethod->new(
#		data_source  => "DBI:Proxy:hostname=192.168.1.1;port=7015;dsn=DBI:Oracle:PERSONS",
		data_source => "DBI:$DBD:",
		user => 'csv',
		pass => 'csv',
		attr => { 'RaiseError' => 0, 'AutoCommit' => 1 },
		methods => \%methods,
		);

	is(ref $db, 'DBIx::LazyMethod', 'Test the constructed object');

        if ($db->is_error) { die $db->{errormessage}; }
	is($db->is_error, 0, 'Test new good instance');

        #my $rv = $db->drop_people_table();
        #if ($db->is_error) { warn $db->{errormessage}."\nAborting..\n"; exit 0; }

        my $rv0 = $db->create_people_table();
        if ($db->is_error) { warn $db->{errormessage}."\nAborting..\n"; exit 0; }

	print STDERR "Return for create_people_table: $rv0\n" if DEBUG;
	is($rv0, '0E0', 'Test create table: no rows affected');

        my $rv1 = $db->create_people_entry(alias=>3,name=>'Johnny Login');
        if ($db->is_error) { warn $db->{errormessage}."\nAborting..\n"; exit 0; }
	
	print STDERR "Return for create_people_entry: $rv1\n" if DEBUG;
	is($rv1, 1, 'Test create entry: 3, Johnny Login');

        my $rv2 = $db->create_people_entry(alias=>42,name=>'Ronnie Raket');
        if ($db->is_error) { warn $db->{errormessage}."\nAborting..\n"; exit 0; }
	
	print STDERR "Return for create_people_entry: $rv2\n" if DEBUG;
	is($rv2, 1, 'Test create entry: 42, Ronnie Raket');

        my $rv3 = $db->create_people_entry(alias=>5,name=>'mil r0vgart');
        if ($db->is_error) { warn $db->{errormessage}."\nAborting..\n"; exit 0; }
	
	print STDERR "Return for set_people_name_by_alias: $rv3\n" if DEBUG;
	is($rv3, 1, 'Test update entry: 5, mil r0vgart');

        my $rv4 = $db->set_people_name_by_alias(alias=>42,name=>'Arne Raket');
        if ($db->is_error) { warn $db->{errormessage}."\nAborting..\n"; exit 0; }

	print STDERR "Return for set_people_name_by_alias: $rv4\n" if DEBUG;
	is($rv4, 1, 'Test update entry: 42, Arne Raket');

        my $ref0 = $db->get_people_entry_by_alias(alias=>42);
        if ($db->is_error) { warn $db->{errormessage}."\nAborting..\n"; exit 0; }
	
	print STDERR "Return for get_people_entry_by_alias:\n" if DEBUG;
	is(ref $ref0, 'HASH', 'Test get entry: 42, Arne Raket');

        my ($rv5) = $db->get_people_alias_by_name(name=>'Johnny Login');
        if ($db->is_error) { warn $db->{errormessage}."\nAborting..\n"; exit 0; }
	
	print STDERR "Return for get_people_alias_by_name:\n" if DEBUG;
	is($rv5, 3, 'Test get entry: 3, Johnny Login');

        my ($rv66) = $db->get_people_alias_by_name(name=>'Ib Rene Cairo');
        if ($db->is_error) { warn $db->{errormessage}."\nAborting..\n"; exit 0; }
	
	print STDERR "Return for get_people_alias_by_name:\n" if DEBUG;
	is($rv66, undef, 'Test get entry: non-existant');

        my $ref1 = $db->get_all_people_entries();
        if ($db->is_error) { warn $db->{errormessage}."\nAborting..\n"; exit 0; }
	
	print STDERR "Return for get_all_people_entries:\n" if DEBUG;
	is(ref $ref1, 'ARRAY', 'Test get all entries: ARRAY');

        my ($rv6) = $db->get_people_count();
        if ($db->is_error) { warn $db->{errormessage}."\nAborting..\n"; exit 0; }
	
	print STDERR "Return for get_people_count:\n" if DEBUG;
	is($rv6, 3, 'Test entry count: 3');

	print STDERR "\n[test] expect a warning here\n";
        my $rv7 = $db->delete_people_entry_by_alias(name=>'This will give a warning',alias=>42);
        if ($db->is_error) { warn $db->{errormessage}."\nAborting..\n"; exit 0; }

	print STDERR "Return for delete_people_entry_by_alias: $rv7\n" if DEBUG;
	is($rv7, 1, 'Test entry delete success: 1');

        my $rv8 = $db->drop_people_table();
        if ($db->is_error) { warn $db->{errormessage}."\nAborting..\n"; exit 0; }

	print STDERR "Return for drop_people_table: $rv8\n" if DEBUG;
	is($rv8, -1, 'Test drop table: unknown rows affected');

	undef $db;
