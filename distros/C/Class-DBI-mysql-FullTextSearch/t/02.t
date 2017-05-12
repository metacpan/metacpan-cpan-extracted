#!/usr/bin/perl -w

use strict;

use Test::More;

my @connection = do {
	my $db   = $ENV{DBD_MYSQL_DBNAME} || 'test';
	my $user = $ENV{DBD_MYSQL_USER}   || '';
	my $pass = $ENV{DBD_MYSQL_PASSWD} || '';
	("dbi:mysql:$db", $user, $pass);
};
my $table = $ENV{DBD_MYSQL_TABLE} || 'tbcdbitest';

eval { DBI->connect(@connection) };
plan $@ ? (skip_all => "Can't connect to test database") : (tests => 4);

package Song;
use base 'Class::DBI::mysql';
use Class::DBI::mysql::FullTextSearch;
__PACKAGE__->set_db('Main', "dbi:mysql:test", '', '');
__PACKAGE__->table($table);
__PACKAGE__->drop_table;
__PACKAGE__->create_table(
	qq{
		id MEDIUMINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
		title VARCHAR(255) NOT NULL
	}
);
__PACKAGE__->set_up_table;
__PACKAGE__->full_text_search(find_some => [qw/title/]);

package main;
eval {
	my @titles = ("Happy as 23 Larrys", "Script For a Happy Jester's Tear",);
	Song->create({ title => $_ }) foreach @titles;
	my @by_title = Song->find_some('happy');
	is scalar @by_title, 2, "Found the songs";
};
is $@, '', "No errors";
ok(Song->_find_some_handle->drop, "Clean up index");
ok(Song->drop_table, "Clean up table");

