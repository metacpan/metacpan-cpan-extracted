use strict;
use warnings;

use Test::More;
use DBIO::Optional::Dependencies ();

# The catalog readers against a real Informix server (karr k16 / k20): the
# statements, the coltype / collength / sysdefaults encodings and the
# constraint-to-index links, measured on Informix 15.0.1. Creates and drops
# the tables "zz_ix_parent" and "zz_ix_child".

plan skip_all => 'Test needs ' . DBIO::Optional::Dependencies->req_missing_for('test_rdbms_informix')
  unless DBIO::Optional::Dependencies->req_ok_for('test_rdbms_informix');

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_INFORMIX_$_" } qw/DSN USER PASS/};
plan skip_all => 'Set $ENV{DBIO_TEST_INFORMIX_DSN}, _USER and _PASS to run this test'
  unless $dsn;

use DBIO::Informix::Introspect;
use DBIO::Informix::Storage;

# the storage connects the way it does for the ORM (DELIMIDENT)
my $storage = DBIO::Informix::Storage->new;
$storage->connect_info([ $dsn, $user, $pass, { RaiseError => 1, PrintError => 0 } ]);
my $dbh = $storage->dbh;

sub cleanup { eval { $dbh->do("DROP TABLE $_") } for qw(zz_ix_child zz_ix_parent) }
cleanup();
END { cleanup() if $dbh }

$dbh->do(<<'SQL');
CREATE TABLE zz_ix_parent (
  id      SERIAL NOT NULL,
  code    VARCHAR(20,5) NOT NULL,
  name    VARCHAR(50) DEFAULT 'x y',
  n       INTEGER DEFAULT -7,
  price   DECIMAL(10,2) DEFAULT 3.14,
  made    DATETIME YEAR TO FRACTION(5) DEFAULT CURRENT YEAR TO FRACTION(5),
  d       DATE DEFAULT TODAY,
  who     CHAR(8) DEFAULT USER,
  PRIMARY KEY (id) CONSTRAINT zz_ix_parent_pk
)
SQL
$dbh->do('CREATE UNIQUE INDEX zz_ix_parent_code ON zz_ix_parent (code DESC)');
$dbh->do(<<'SQL');
CREATE TABLE zz_ix_child (
  a   INTEGER NOT NULL,
  b   INTEGER NOT NULL,
  pid INTEGER,
  PRIMARY KEY (a, b),
  FOREIGN KEY (pid) REFERENCES zz_ix_parent (id) ON DELETE CASCADE
)
SQL
$dbh->do('CREATE INDEX zz_ix_child_b ON zz_ix_child (b, a)');

# the database the dsn names (dbinfo pads with blanks)
my ($db) = $dbh->selectrow_array(q{SELECT DBINFO('dbname') FROM systables WHERE tabid = 1});
$db =~ s/\s+\z//;

is(DBIO::Informix::Introspect->new(dbh => $dbh)->schema, $db, 'default schema is the connected database');
my $m = DBIO::Informix::Introspect->new(dbh => $dbh)->model;

# tables: owned by the connecting user (the database owner, 'informix' too)
is_deeply([ sort grep { /^zz_ix_/ } keys %{ $m->{tables} } ],
  [qw(zz_ix_child zz_ix_parent)], 'tables found, whoever owns them');
is $m->{tables}{zz_ix_parent}{kind}, 'table', 'kind';
unlike $m->{tables}{zz_ix_parent}{owner}, qr/\s\z/, 'owner without CHAR padding';

my %p = map { $_->{column_name} => $_ } @{ $m->{columns}{zz_ix_parent} };
my %c = map { $_->{column_name} => $_ } @{ $m->{columns}{zz_ix_child} };

# types and sizes
is $p{id}{data_type},    'serial',  'SERIAL';
is $c{a}{data_type},     'integer', 'INTEGER is integer, not smallint';
is $p{code}{data_type},  'varchar', 'VARCHAR';
is $p{code}{size},       20,        'VARCHAR(20,5): the maximum';
is_deeply $p{price}{size}, [10, 2], 'DECIMAL(10,2)';
is $p{made}{data_type},  'datetime year to fraction(5)', 'DATETIME qualifiers';
is $p{who}{size},        8,         'CHAR(8) has a size';

# NOT NULL, key, defaults
is $p{id}{not_null}, 1, 'NOT NULL'; is $p{name}{not_null}, 0, 'nullable';
is $p{id}{is_pk}, 1, 'PK column'; is $p{code}{is_pk}, 0, 'non-key column';
is $c{a}{pk_position}, 1, 'composite PK position 1';
is $c{b}{pk_position}, 2, 'composite PK position 2';
is $p{name}{default_value},  'x y',  'character default';
is $p{n}{default_value},     '-7',   'integer default without its encoded prefix';
is $p{price}{default_value}, '3.14', 'decimal default';
is_deeply $p{d}{default_value},   \'today', 'TODAY';
is_deeply $p{who}{default_value}, \'user',  'USER';
ok ref $p{made}{default_value}, 'CURRENT';

# indexes: the explicit ones only; the ones created for the constraints
# (named like " 136_41") are the PK / FK, modelled there, and their names
# differ from one database to the next
is_deeply [ sort keys %{ $m->{indexes}{zz_ix_parent} // {} } ], ['zz_ix_parent_code'],
  'no index of a constraint reported';
is_deeply $m->{indexes}{zz_ix_parent}{zz_ix_parent_code}{columns}, ['code'], 'index columns';
is $m->{indexes}{zz_ix_parent}{zz_ix_parent_code}{unique}, 1, 'unique index';
is_deeply [ sort keys %{ $m->{indexes}{zz_ix_child} // {} } ], ['zz_ix_child_b'],
  'child: only the explicit index';
is_deeply $m->{indexes}{zz_ix_child}{zz_ix_child_b}{columns}, ['b', 'a'], 'index column order';

# foreign key
my @fk = @{ $m->{foreign_keys}{zz_ix_child} // [] };
is scalar @fk, 1, 'one foreign key';
is_deeply $fk[0]{from_columns}, ['pid'], 'from_columns';
is $fk[0]{to_table}, 'zz_ix_parent', 'to_table';
is_deeply $fk[0]{to_columns}, ['id'], 'to_columns';
is $fk[0]{del_rule}, 'C', 'ON DELETE CASCADE';

done_testing;
