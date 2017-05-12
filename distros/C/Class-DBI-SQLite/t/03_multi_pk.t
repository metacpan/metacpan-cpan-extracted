use strict;
use Test::More tests => 2;

use Class::DBI::SQLite;
use DBI;
use Carp qw( confess );

unlink './t/multi_pk.db' if -e './t/multi_pk.db';

my $dbh = DBI->connect(
    'dbi:SQLite:dbname=./t/multi_pk.db', '', '',
    {
	RaiseError => 1,
	PrintError => 1,
	AutoCommit => 1
    }
);

$dbh->do('CREATE TABLE multi_pk (revision INTEGER, version INTEGER, msg TEXT, PRIMARY KEY (revision,version) )');

package MultiPK;
use base qw(Class::DBI::SQLite);

__PACKAGE__->connection('dbi:SQLite:dbname=./t/multi_pk.db', '', '');
__PACKAGE__->set_up_table('multi_pk');

package main;

my @pks = sort MultiPK->primary_columns;
is_deeply( \@pks, [qw(revision version)] );

for (1..10) {
    MultiPK->create({
        revision  => $_,
	version  => $_,
	msg      => "version $_",
    });
}

my $obj = MultiPK->retrieve( revision => 3, version => 3 );
is($obj->msg, 'version 3');

END {
    unlink './t/multi_pk.db';
}
