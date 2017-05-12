#!perl

use 5.006;
use strict;
use warnings;

use Test::More tests => 11;
use DBI;

my $dbh;

ok( $dbh = DBI->connect( 'dbi:SQLite:dbname=dbfile', '', '', {
            RaiseError => 1,
            AutoCommit => 1,
            RootClass  => 'DBIx::NamedBinding',
        },
    ), 'Connect to dbfile');

ok( $dbh->do('DROP TABLE IF EXISTS bar')           &&
    $dbh->do('CREATE TABLE bar (foo int)')         &&
    $dbh->do('INSERT INTO bar (foo) VALUES (1)')   &&
    $dbh->do('INSERT INTO bar (foo) VALUES (2)')   &&
    $dbh->do('INSERT INTO bar (foo) VALUES (3)')   &&
    $dbh->do('INSERT INTO bar (foo) VALUES (4)')   &&
    $dbh->do('INSERT INTO bar (foo) VALUES (5)')   &&
    $dbh->do('INSERT INTO bar (foo) VALUES (6)') ,
    'Create test database'
);

my $sth;
ok( $sth = $dbh->prepare('SELECT foo FROM bar WHERE foo > :foo'),
    'Prepare SELECT'
);

ok( ! defined $sth->bind_param(  ), 'Undefined parameter name' );
ok( ! defined $sth->bind_param( '' => 0  ), 'Missing parameter name');
ok( ! defined $sth->bind_param( gorp => 0 ), 'Using undeclared parameter placeholder');
ok( $sth->bind_param( foo => 3 ), 'Bind parameter value');
ok( $sth->execute(), 'Execute query');

cmp_ok( $sth->fetchrow_array, '==', 4, 'Get 4');
cmp_ok( $sth->fetchrow_array, '==', 5, 'Get 5');
cmp_ok( $sth->fetchrow_array, '==', 6, 'Get 6');

$sth->finish;
undef $sth;
$dbh->disconnect;
undef $dbh;
unlink 'dbfile';
