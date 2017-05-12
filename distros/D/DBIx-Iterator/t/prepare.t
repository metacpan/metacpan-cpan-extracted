#!perl

use strict;
use warnings;
use Test::More;

use DBI;
use SQL::Statement 1.401; # to make our 'SELECT 1' query work

use lib 'lib';
use DBIx::Iterator;

my $dbh = DBI->connect('dbi:DBM:dbm_type=DB_File');
my $db = DBIx::Iterator->new($dbh);
can_ok($db, 'prepare');

eval { $db->prepare() };
pass('$db->prepare() should fail on undefined queries') if $@;

my $st = $db->prepare('SELECT 1');
isa_ok($st, 'DBIx::Iterator::Statement');
can_ok($st, 'db', 'sth');

is( $st->db, $db, 'Prepared statement has pointer to database in db()' );
is( ref( $st->sth ), ref( $dbh->prepare('SELECT 1') ), 'Statement handles returned by $st->sth() are DBI statement handles' );

done_testing();
