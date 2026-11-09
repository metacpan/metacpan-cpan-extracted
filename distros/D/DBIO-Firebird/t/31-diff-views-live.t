use strict;
use warnings;
use Test::More;

# LIVE: views in the diff (karr k61, replacing the refusal of karr k33).
#
# Against a server, through Deploy->diff / upgrade:
#
#  * a view the database lacks is created with CREATE VIEW (here
#    together with a new table in the same upgrade), the model then reads
#    its rdb$view_source and the diff is empty;
#  * the same view in the database with other whitespace is no difference;
#  * a view with another definition is dropped before the table changes and
#    created again after them (columns included), and the diff is empty
#    afterwards; so a column only the old definition read can be dropped in
#    the same upgrade;
#  * a view only the database has is dropped (DROP VIEW, never DROP TABLE);
#  * a replacement the server refuses (a procedure uses the view, or an
#    unchanged view reads the changed one) is the server's own error, the
#    view stays as it was;
#  * a name that is a table in the database and a view in the schema is
#    refused before any statement.
#
# Skipped unless a DSN is provided (as t/19):
#
#   DBIO_TEST_FIREBIRD_DSN / _USER / _PASS
#
# WARNING: creates and drops the tables "k61_base", "k61_new" and "k61_clash",
# the views "k61_view", "k61_outer" and the procedure "k61_proc".

my $dsn  = $ENV{DBIO_TEST_FIREBIRD_DSN};
my $user = $ENV{DBIO_TEST_FIREBIRD_USER};
my $pass = $ENV{DBIO_TEST_FIREBIRD_PASS};

plan skip_all => 'Set DBIO_TEST_FIREBIRD_DSN, _USER, _PASS to run the live view diff test'
  unless $dsn;

eval { require DBI; require DBD::Firebird; 1 }
  or plan skip_all => 'DBI / DBD::Firebird not installed';

use DBIO::Core;
use DBIO::Schema;
use DBIO::ResultSource::View;
use DBIO::Firebird::Deploy;

my %VCOL = (
  id  => { data_type => 'integer' },
  val => { data_type => 'varchar', size => 10, is_nullable => 1 },
);

my $seq = 0;
# view => [ name, definition, @columns ] (any number of views), new_table, clash
sub schema_with {
  my (%o) = @_;
  my $sc = 'K61Live::S' . ++$seq;
  no strict 'refs';
  @{"${sc}::ISA"} = ('DBIO::Schema');
  $sc->load_components('Firebird');
  my $mk = sub {
    my ($name, $table, $cols) = @_;
    my $rc = "${sc}::Result::$name";
    @{"${rc}::ISA"} = ('DBIO::Core');
    $rc->table($table);
    $rc->add_columns(@$cols);
    $rc->set_primary_key('id');
    $sc->register_class($name => $rc);
  };
  $mk->(Base => 'k61_base', [ id => { data_type => 'integer' }, val => { data_type => 'varchar', size => 10, is_nullable => 1 } ]);
  $mk->(New  => 'k61_new',  [ id => { data_type => 'integer' } ]) if $o{new_table};
  my $n = 0;
  for my $spec (@{ $o{views} // [] }) {
    my ($name, $def, @cols) = @$spec;
    my $v = DBIO::ResultSource::View->new({ name => $name, is_virtual => 0, view_definition => $def });
    $v->add_columns(map { ($_ => { %{ $VCOL{$_} } }) } @cols);
    $sc->register_source('View' . ++$n => $v);
  }
  return $sc->connect($dsn, $user, $pass, { quote_names => 1, on_connect_call => 'use_softcommit' });
}

my $base = schema_with();
eval { $base->storage->dbh->do('SELECT 1 FROM rdb$database'); 1 }
  or plan skip_all => "Cannot reach Firebird server: $@";

my $other = DBI->connect($dsn, $user, $pass, { RaiseError => 1, PrintError => 0, AutoCommit => 1, ib_dialect => 3 })
  or plan skip_all => 'Cannot connect: ' . DBI->errstr;
$other->func(-lock_resolution => { wait => 10 }, 'ib_set_tx_param');
$SIG{__WARN__} = sub { warn @_ unless $_[0] =~ /^non-transactional DDL on |problem parsing SQL_/ };

my @open = ($base);
sub close_all { $_->storage->disconnect for @open; @open = () }
sub cleanup {
  close_all();
  eval { $other->do($_) } for
    'DROP PROCEDURE "k61_proc"', 'DROP VIEW "k61_outer"', 'DROP VIEW "k61_view"',
    'DROP TABLE "k61_clash"', 'DROP TABLE "k61_new"', 'DROP TABLE "k61_base"';
}
cleanup();
sub schema { my $s = schema_with(@_); push @open, $s; $s }
sub kind_of { my ($n) = @_; my $k = ($other->selectrow_array(q{SELECT CASE WHEN rdb$view_blr IS NULL THEN 'table' ELSE 'view' END FROM rdb$relations WHERE TRIM(rdb$relation_name) = ?}, undef, $n))[0]; $k =~ s/\s+$// if defined $k; $k }
sub source_of { my ($n) = @_; ($other->selectrow_array(q{SELECT rdb$view_source FROM rdb$relations WHERE TRIM(rdb$relation_name) = ?}, undef, $n))[0] }
sub columns_of { my ($n) = @_; join ',', map { s/\s+$//r } map { $_->[0] } @{ $other->selectall_arrayref(q{SELECT rdb$field_name FROM rdb$relation_fields WHERE TRIM(rdb$relation_name) = ? ORDER BY rdb$field_position}, undef, $n) } }
sub diff_of { my ($s) = @_; DBIO::Firebird::Deploy->new(schema => $s)->diff }

ok eval { DBIO::Firebird::Deploy->new(schema => $base)->install; 1 }, 'the base table is installed' or diag $@;

my $both = [ 'k61_view', 'SELECT "id", "val" FROM "k61_base"', qw(id val) ];

# --- a view only the schema has, with a new table in the same upgrade -------------------
close_all();
my $with = schema(views => [ $both ], new_table => 1);
my $d = eval { diff_of($with) };
ok $d && $d->has_changes, 'a view the database lacks: reported';
like $d && $d->summary, qr/\+ view: k61_view/, '... as a view';
like $d && $d->as_sql, qr/CREATE VIEW "k61_view" AS SELECT "id", "val" FROM "k61_base";/, '... CREATE VIEW';
ok eval { DBIO::Firebird::Deploy->new(schema => $with)->upgrade; 1 }, 'upgrade creates it' or diag $@;
is kind_of('k61_view'), 'view', '... a view, not a table';
is kind_of('k61_new'), 'table', '... and the new table of the same diff exists';
close_all();
my $d1 = eval { diff_of(schema(views => [ $both ], new_table => 1)) };
ok $d1 && !$d1->has_changes, 'the diff after the upgrade is empty' or diag $d1 ? $d1->summary : $@;

# --- the same view with other whitespace ----------------------------------------------------
close_all();
$other->do('DROP VIEW "k61_view"');
$other->do(qq{CREATE VIEW "k61_view" AS\n   SELECT "id",\n          "val"\n     FROM "k61_base"  });
my $d2 = eval { diff_of(schema(views => [ $both ], new_table => 1)) };
ok $d2 && !$d2->has_changes, 'the same definition, other whitespace: no difference' or diag $d2 ? $d2->summary : $@;

# --- a view with another definition: replaced --------------------------------------------------
close_all();
my $only_id = [ 'k61_view', 'SELECT "id" FROM "k61_base"', qw(id) ];
my $d3 = eval { diff_of(schema(views => [ $only_id ], new_table => 1)) };
ok $d3 && $d3->has_changes, 'a changed definition: reported';
like $d3 && $d3->summary, qr/~ view: k61_view/, '... as a change';
ok eval { DBIO::Firebird::Deploy->new(schema => schema(views => [ $only_id ], new_table => 1))->upgrade; 1 }, 'upgrade replaces it' or diag $@;
is columns_of('k61_view'), 'id', '... the view now has the new columns';
like source_of('k61_view'), qr/^SELECT "id" FROM "k61_base"$/, '... and the new definition';
close_all();
my $d4 = eval { diff_of(schema(views => [ $only_id ], new_table => 1)) };
ok $d4 && !$d4->has_changes, 'the diff after the replace is empty' or diag $d4 ? $d4->summary : $@;

# --- a replacement the server refuses: its error, the view unchanged ---------------------------------
close_all();
$other->do('DROP VIEW "k61_view"');
$other->do('CREATE VIEW "k61_view" AS SELECT "id", "val" FROM "k61_base"');
$other->do(q{CREATE PROCEDURE "k61_proc" RETURNS (x varchar(10)) AS begin select first 1 "val" from "k61_view" into :x; suspend; end});
my $refused = schema(views => [ $only_id ], new_table => 1);
ok !eval { DBIO::Firebird::Deploy->new(schema => $refused)->upgrade; 1 }, 'a replacement the server refuses: upgrade dies';
like "$@", qr/dependenc|unsuccessful metadata update/i, '... with the server\'s error' ;
unlike "$@", qr/refusing to diff/, '... not a refusal of the diff';
close_all();
is columns_of('k61_view'), 'id,val', '... and the view is as it was';
$other->do('DROP PROCEDURE "k61_proc"');

# --- an unchanged view reading the changed one: the server's error, loud ------------------------------
close_all();
$other->do('CREATE VIEW "k61_outer" AS SELECT "id" FROM "k61_view"');
my $outer = [ 'k61_outer', 'SELECT "id" FROM "k61_view"', qw(id) ];
my $dep = schema(views => [ $only_id, $outer ], new_table => 1);
ok !eval { DBIO::Firebird::Deploy->new(schema => $dep)->upgrade; 1 }, 'an unchanged view reads the changed one: upgrade dies';
like "$@", qr/dependenc|in use|unsuccessful metadata update/i, '... with the server\'s error';
unlike "$@", qr/refusing to diff/, '... not a refusal of the diff';
close_all();
is columns_of('k61_view'), 'id,val', '... and the changed view is as it was';
$other->do('DROP VIEW "k61_outer"');

# --- a view that stops reading a column, and the column is dropped in the same upgrade ---------------
close_all();
$other->do('DROP VIEW "k61_view"');
$other->do('ALTER TABLE "k61_base" ADD "c" integer');
$other->do('CREATE VIEW "k61_view" AS SELECT "id", "c" FROM "k61_base"');
my $drop_c = schema(views => [ $only_id ], new_table => 1);
my $dc = eval { diff_of($drop_c) };
ok $dc && $dc->has_changes, 'a changed view and a column only it read: reported';
like $dc && $dc->as_sql, qr/\ADROP VIEW "k61_view";.*ALTER TABLE "k61_base" DROP "c";.*CREATE VIEW "k61_view" AS SELECT "id" FROM "k61_base";\z/s, '... DROP VIEW, the column drop, CREATE VIEW';
ok eval { DBIO::Firebird::Deploy->new(schema => $drop_c)->upgrade(allow_destructive => 1); 1 }, 'upgrade drops the column under the changed view' or diag $@;
is columns_of('k61_base'), 'id,val', '... the column is gone';
is columns_of('k61_view'), 'id', '... and the view has the new definition';
close_all();
my $d7 = eval { diff_of(schema(views => [ $only_id ], new_table => 1)) };
ok $d7 && !$d7->has_changes, 'the diff afterwards is empty' or diag $d7 ? $d7->summary : $@;

# --- a view only the database has: dropped -----------------------------------------------------------------
close_all();
$other->do('DROP TABLE "k61_new"') if kind_of('k61_new');
my $no_view = schema();
my $d5 = eval { diff_of($no_view) };
ok $d5 && $d5->has_changes, 'a view the schema lacks: reported';
is $d5 && $d5->as_sql, 'DROP VIEW "k61_view";', '... DROP VIEW, no DROP TABLE';
ok eval { DBIO::Firebird::Deploy->new(schema => $no_view)->upgrade(allow_destructive => 1); 1 }, 'upgrade drops it' or diag $@;
is kind_of('k61_view'), undef, '... the view is gone';
is kind_of('k61_base'), 'table', '... the table it read is still there';

# --- a table in the database, a view in the schema: refused ----------------------------------------------------
close_all();
$other->do('CREATE TABLE "k61_clash" ("id" integer)');
my $clash = schema(views => [ [ 'k61_clash', 'SELECT "id" FROM "k61_base"', qw(id) ] ]);
my $d6 = eval { diff_of($clash) };
ok $d6 && $d6->has_changes, 'a table that is a view in the schema: reported';
# released (the diff also drops a view the schema lacks): the release never covers a refusal
ok !eval { DBIO::Firebird::Deploy->new(schema => $clash)->upgrade(allow_destructive => 1); 1 }, '... upgrade dies';
like "$@", qr/"k61_clash": the database has a table and the schema a view/, '... naming it';
is kind_of('k61_clash'), 'table', '... and the table is untouched';

cleanup();
$other->disconnect;
done_testing;
