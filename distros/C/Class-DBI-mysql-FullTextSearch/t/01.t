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
plan $@ ? (skip_all => "Can't connect to test database") : (tests => 15);

package Sheep;

use base 'Class::DBI::mysql';
use Class::DBI::mysql::FullTextSearch;
__PACKAGE__->set_db(Main => @connection);
__PACKAGE__->table($table);
__PACKAGE__->drop_table;
__PACKAGE__->create_table(
	q{
		id mediumint not null auto_increment primary key,
		title varchar(255) not null default '',
		keywords varchar(255) not null default ''
	}
);

__PACKAGE__->set_up_table;
__PACKAGE__->full_text_search(find_some => [qw/title keywords/]);

package main;

my $sheep = Sheep->create(
	{
		title    => 'Beowulf Genomics',
		keywords => 'Teladorsagia circumcincta, Haemonchus contortus',
	}
);
isa_ok $sheep => 'Sheep';
ok $sheep->_find_some_handle, 'DBIx::FullTextSearch';

my @by_title = Sheep->find_some('genomics');
is scalar @by_title, 1, "Found an article by title: $by_title[0]";
my $found = $by_title[0];
isa_ok $found => 'Sheep';
is $found->id, $sheep->id, " the correct one";

my @by_keywords = Sheep->find_some('circumcincta');
is scalar @by_keywords, 1, "Found an article by keyword";
is $by_keywords[0]->id, $sheep->id, " the correct one";

$sheep->keywords("Haemonchus contortus");
ok $sheep->update, "No more circumcincta";

my @now = Sheep->find_some('circumcincta');
is scalar @now, 0, "So no-one interested in circumcincta any more :(";

my $sheep2 = Sheep->create(
	{
		title    => 'Ars Magnifica',
		keywords => 'Haemonchus extraordinus contortus',
	}
);

my @t_sorted = Sheep->find_some('contortus', { sort => 'title' });
is scalar @t_sorted, 2, "Now two sheep";
is $t_sorted[0]->title, 'Ars Magnifica', "Ordered correctly by name";

my @n_sorted = Sheep->find_some('contortus', { sort => 'keywords' });
is scalar @n_sorted, 2, "Still two sheep";
is $n_sorted[0]->keywords, "Haemonchus contortus",
	"Ordered correctly by keywords";

ok($sheep->_find_some_handle->drop, "Clean up index");
ok(Sheep->drop_table, "Clean up table");

