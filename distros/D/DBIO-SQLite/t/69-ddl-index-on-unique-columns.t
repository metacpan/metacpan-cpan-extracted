use strict;
use warnings;
use Test::More;

BEGIN {
  eval { require DBD::SQLite; 1 } or plan skip_all => 'DBD::SQLite required';
}

use DBIO::Core ();
use DBIO::Schema ();
use DBIO::SQLite::DDL ();
use DBIO::SQLite::Deploy ();
use DBIO::SQLite::Introspect ();

# karr k79, shared case ddl-index-on-unique-columns: a UNIQUE (a, b) line is
# backed by an index SQLite keeps itself, so an index declared over the same
# columns -- plain or unique -- is a second one for the same lookups.
# install_ddl does not write it. What stays written is every index that is a
# different object: another column order, a subset, one with a WHERE or an
# expression.

{
  package IdxUq::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('SQLite');
}
{
  package IdxUq::Schema::Result::Child;
  use base 'DBIO::Core';
  __PACKAGE__->load_components('SQLite::Result');
  __PACKAGE__->table('child');
  __PACKAGE__->add_columns(
    id => { data_type => 'integer', is_auto_increment => 1, is_nullable => 0 },
    a  => { data_type => 'integer', is_nullable => 0 },
    b  => { data_type => 'integer', is_nullable => 0 },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->add_unique_constraint(child_ab => [ 'a', 'b' ]);
  __PACKAGE__->sqlite_index(dup_ab      => { columns => [ 'a', 'b' ] });
  __PACKAGE__->sqlite_index(order_ba    => { columns => [ 'b', 'a' ] });
  __PACKAGE__->sqlite_index(only_a      => { columns => ['a'] });
  __PACKAGE__->sqlite_index(partial_ab  => { columns => [ 'a', 'b' ], where => 'a > 0' });
  __PACKAGE__->sqlite_index(unique_ab   => { columns => [ 'a', 'b' ], unique => 1 });
  __PACKAGE__->sqlite_index(unique_ba   => { columns => [ 'b', 'a' ], unique => 1 });
  __PACKAGE__->sqlite_index(unique_part => { columns => [ 'a', 'b' ], unique => 1, where => 'a > 0' });
  # the canonical declaration (Cake idx / indices): same rule, one for both
  __PACKAGE__->result_source_instance->add_index_declaration(
    { name => 'canon_unique_ab', columns => [ 'a', 'b' ], unique => 1 });
  __PACKAGE__->result_source_instance->add_index_declaration(
    { name => 'canon_plain_ab', columns => [ 'a', 'b' ] });
}
IdxUq::Schema->register_class(Child => 'IdxUq::Schema::Result::Child');

sub index_names {
  my ($schema) = @_;
  my $model = DBIO::SQLite::Introspect->new(dbh => $schema->storage->dbh)->model;
  return [ sort grep { ($model->{indexes}{child}{$_}{origin} // '') eq 'c' }
           keys %{ $model->{indexes}{child} || {} } ];
}

my $ddl = DBIO::SQLite::DDL->install_ddl('IdxUq::Schema');

like $ddl, qr/^  UNIQUE \("a", "b"\)/m, 'the unique constraint is written';
for my $dup (qw(dup_ab unique_ab canon_unique_ab canon_plain_ab)) {
  unlike $ddl, qr/INDEX "\Q$dup\E"/,
    "$dup, over exactly the unique constraint's columns, is not written";
}
for my $kept (qw(order_ba only_a partial_ab unique_ba unique_part)) {
  like $ddl, qr/INDEX "\Q$kept\E"/, "$kept is another object and is written";
}

my $schema = IdxUq::Schema->connect('dbi:SQLite::memory:');
$schema->deploy;

is_deeply index_names($schema), [qw(only_a order_ba partial_ab unique_ba unique_part)],
  'the database holds the five, none of the duplicates';

ok !DBIO::SQLite::Deploy->new(schema => $schema)->diff->has_changes,
  'install, then diff against the same declaration, is empty';

# A database deployed before this: dup_ab exists. The diff takes it away, and
# the unique constraint keeps its own index.
my $old = IdxUq::Schema->connect('dbi:SQLite::memory:');
$old->deploy;
$old->storage->dbh->do($_) for
  'CREATE INDEX "dup_ab" ON "child" ("a", "b")',
  'CREATE UNIQUE INDEX "unique_ab" ON "child" ("a", "b")';
my $diff = DBIO::SQLite::Deploy->new(schema => $old)->diff;
ok $diff->has_changes, 'a database that holds the duplicates differs';
like $diff->as_sql, qr/DROP INDEX "?dup_ab"?/, 'by dropping the plain one';
like $diff->as_sql, qr/DROP INDEX "?unique_ab"?/, 'and the unique one';
DBIO::SQLite::Deploy->new(schema => $old)->apply($diff, allow_destructive => 1);
is_deeply index_names($old), [qw(only_a order_ba partial_ab unique_ba unique_part)],
  'after the upgrade the duplicates are gone';
{
  my $dbh = $old->storage->dbh;
  $dbh->do('INSERT INTO "child" ("id", "a", "b") VALUES (1, 1, 1)');
  ok !eval { $dbh->do('INSERT INTO "child" ("id", "a", "b") VALUES (2, 1, 1)'); 1 },
    'and the unique constraint still refuses a second (1, 1)';
}
ok !DBIO::SQLite::Deploy->new(schema => $old)->diff->has_changes,
  'and the next diff is empty';

done_testing;
