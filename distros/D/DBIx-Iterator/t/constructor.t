#!perl

use strict;
use warnings;
use Test::More;

use DBI;

use lib 'lib';
use DBIx::Iterator;

can_ok('DBIx::Iterator', 'new');

eval { DBIx::Iterator->new() };
pass("Constructor doesn't accept undefined database handles") if $@;

my $dbh = DBI->connect('dbi:DBM:dbm_type=DB_File');
my $db = DBIx::Iterator->new($dbh);
isa_ok($db, 'DBIx::Iterator');

can_ok($db, 'dbh');
is( $db->dbh, $dbh, 'Database handle provided in constructor is the same as dbh() returns' );

done_testing();
