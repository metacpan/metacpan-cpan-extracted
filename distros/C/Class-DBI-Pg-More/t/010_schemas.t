use strict;
use warnings FATAL => 'all';

use Test::More tests => 4;
use Test::TempDatabase;

BEGIN { use_ok( 'Class::DBI::Pg::More' ); }

my $tdb = Test::TempDatabase->create(dbname => 'ht_class_dbi_test',
		dbi_args => { RootClass => 'DBIx::ContextualFetch' });
my $dbh = $tdb->handle;
$dbh->do('SET client_min_messages TO error');
$dbh->do(q{ CREATE TABLE t1 (id serial primary key);
	create schema foo; create table foo.t1 (id serial primary key); });

package T1;
use base 'Class::DBI::Pg::More';
sub db_Main { return $dbh; }

package main;

T1->set_up_table('t1');
is(scalar(T1->_essential), 1);
is_deeply(Class::DBI::Pg::More->find_columns($dbh, 't1'), [ [ 'id', 'integer', 'NO' ] ]);
is_deeply(Class::DBI::Pg::More->find_primary_key($dbh, 't1'), [ 'id' ]);

