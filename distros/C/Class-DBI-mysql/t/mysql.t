#!/usr/bin/perl -w

use strict;
use Test::More;

my $HAVE_TP = eval { require Time::Piece::MySQL };

plan tests => 8;

use_ok "Class::DBI::mysql";

#-------------------------------------------------------------------------
# Let the testing begin
#-------------------------------------------------------------------------

package Foo;

use base 'Class::DBI::mysql';

# Find a test database to use.

my $db   = $ENV{DBD_MYSQL_DBNAME} || 'test';
my $user = $ENV{DBD_MYSQL_USER}   || '';
my $pass = $ENV{DBD_MYSQL_PASSWD} || '';
my $tbl  = $ENV{DBD_MYSQL_TABLE}  || 'tbcdbitest';

__PACKAGE__->set_db(Main => "dbi:mysql:$db", $user => $pass);
__PACKAGE__->table($tbl);
__PACKAGE__->drop_table;
__PACKAGE__->create_table(q{
	id     MEDIUMINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
	Name   VARCHAR(50)        NOT NULL,
	val    SMALLINT UNSIGNED  NOT NULL,
	mydate TIMESTAMP          NOT NULL,
	Myvals ENUM('foo', 'bar')
});
__PACKAGE__->set_up_table;
__PACKAGE__->autoinflate(dates => 'Time::Piece') if $HAVE_TP;

END { __PACKAGE__->drop_table }

#-------------------------------------------------------------------------

package main;

can_ok Foo => "name";

Foo->create({ Name => $_ }) foreach (
	('MySQL has now support'), ( 'for full-text search'),
	('Full-text indexes'), ( 'are called collections'),
	('Only MyISAM tables'), ('support collections'),
	('Function MATCH ... AGAINST()'), ('is used to do a search'),
	('Full-text search in MySQL'), ( 'implements vector space model'));

# Test random. Is there a sensible way to test this is actually
# random? For now we'll just ensure that we get something back.
my $obj = Foo->retrieve_random;
isa_ok $obj => "Foo", "Retrieve a random row";

SKIP: { 
	skip "Need Time::Piece::MySQL", 2 unless $HAVE_TP;
	isa_ok $obj->mydate => "Time::Piece", "mydate is a Time::Piece";
	is $obj->mydate->ymd, Time::Piece->new->ymd, "From today";
} 

# Test coltype
my $type = Foo->column_type('Myvals');
like $type, qr/^enum/i, "Myvals is an enum";

my @vals = sort Foo->enum_vals('Myvals');
is_deeply \@vals, [qw/bar foo/], "Enum vals OK";
eval { Foo->enum_vals('mydate') };
ok $@, $@;


