#!/usr/bin/perl

use strict;
use warnings;

use lib '../lib';

use DBI;
use Audit::DBI;


my $dbh = DBI->connect(
	'dbi:SQLite:dbname=test_database',
	'',
	'',
	{
		RaiseError => 1,
	}
);

my $audit = Audit::DBI->new(
	database_handle => $dbh,
);

$audit->create_tables(
	drop_if_exist => 1,
);

$ENV{'REMOTE_ADDR'} = '127.0.0.1';

$audit->record(
	event        => 'Test',
	subject_type => 'test',
	subject_id   => '1',
	information  =>
	{
		test_event_id => 1,
		random_string => 'ABC123',
	},
	search_data  =>
	{
		test_event_id => 1,
		random_string => 'ABC123',
	},
);

$audit->record(
	event        => 'Test',
	subject_type => 'test',
	subject_id   => '2',
	information  =>
	{
		test_event_id => 2,
		random_string => 'ABC1234',
	},
	search_data  =>
	{
		test_event_id => 2,
		random_string => 'ABC1234',
	},
);

