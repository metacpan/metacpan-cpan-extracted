use strict;
use warnings;

use Test::More;

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_PG_$_" } qw(DSN USER PASS)};

plan skip_all => 'Set DBIO_TEST_PG_DSN, _USER and _PASS to run this test'
  unless $dsn;

use DBIO::Core ();
use DBIO::Schema ();
use DBIO::PostgreSQL::Deploy;
use DBIO::PostgreSQL::Introspect;
use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;
use PrivatePgDatabase;

# A server that is not there fails the file, with a plan (karr k113).
LiveServer->require_server;

# LIVE test for karr k121, point 9: a column whose default calls a sequence
# that only the upgrade creates.
#
# WHY it exists: t/110-diff-sequences.t pins the operations the diff builds;
# only a server says that the statements, in their order, are ones it takes.
# Before the fix the diff wrote CREATE TABLE ... DEFAULT nextval('late_id_seq'
# ::regclass) and never the sequence, so every upgrade that brought a serial
# column failed with `relation "late_id_seq" does not exist`.
#
# For every case, in a private database (karr k81):
#
#  1. the old schema is installed, the new one is diffed against it, and the
#     upgrade runs;
#  2. a row inserted afterwards gets its number from the sequence;
#  3. the sequences of the database are those of a database the new schema
#     was installed into, with nothing deployed over it;
#  4. a second diff finds nothing to do.
#
# And the one refusal: a sequence the target has of its own, under the name
# the database holds as the sequence of an identity column, with the way out
# the refusal names.

my @CONNECT = ({ PrintError => 0, PrintWarn => 0 });

my $n = 0;

sub result_class {
  my (%arg) = @_;
  my $class = 'T110::Result::C' . ++$n;
  eval qq{
    package $class;
    use base 'DBIO::Core';
    __PACKAGE__->load_components('PostgreSQL::Result');
    1;
  } or die $@;
  $class->pg_schema($arg{pg_schema}) if $arg{pg_schema};
  $class->table($arg{table});
  $class->add_columns(@{ $arg{columns} });
  $class->set_primary_key(@{ $arg{pk} }) if $arg{pk};
  $class->pg_extra_ddl(@{ $arg{extra} }) if $arg{extra};
  return $class;
}

sub schema_class {
  my ($opt, %results) = @_;
  my $class = 'T110::Schema::S' . ++$n;
  no strict 'refs';
  @{"${class}::ISA"} = ('DBIO::Schema');
  $class->load_components('PostgreSQL');
  $class->pg_schemas(@{ $opt->{pg_schemas} }) if $opt->{pg_schemas};
  $class->register_class($_ => $results{$_}) for sort keys %results;
  return $class;
}

my $BASE = result_class(table => 'base', pk => ['id'],
  columns => [ id => { data_type => 'integer', is_nullable => 0 } ]);

# The sequences of a database as the model has them, without the one field
# that is written for a reader and depends on the session.
sub sequences_of {
  my ($dbh) = @_;
  my $seq = DBIO::PostgreSQL::Introspect->new(dbh => $dbh)->model->{sequences};
  return { map { my %e = %{ $seq->{$_} }; delete $e{owned_by_table}; ($_ => \%e) } keys %$seq };
}

# Install $to into a database of its own and read its sequences.
sub target_sequences {
  my ($tag, $to) = @_;
  my $schema = $to->connect(PrivatePgDatabase->create("${tag}t"), @CONNECT);
  $schema->pg_deploy->install;
  my $seq = sequences_of($schema->storage->dbh);
  $schema->storage->disconnect;
  return $seq;
}

# Install $from, run $prepare on its handle, upgrade to $to. Returns
# ( $schema, $dbh ) connected to the upgraded database.
sub upgraded {
  my ($tag, $label, $from, $to, $prepare, %option) = @_;
  my @db = PrivatePgDatabase->create($tag);

  my $s1 = $from->connect(@db, @CONNECT);
  $s1->pg_deploy->install;
  $prepare->($s1->storage->dbh) if $prepare;
  $s1->storage->disconnect;

  my $schema = $to->connect(@db, @CONNECT);
  my $deploy = $schema->pg_deploy;
  my $diff   = eval { $deploy->diff };
  ok($diff, "$label: the diff is built") or diag $@;
  return unless $diff;
  ok(eval { $deploy->apply($diff, %option); 1 }, "$label: the upgrade runs") or diag $@;
  return ($schema, $schema->storage->dbh, $diff);
}

# The tail of a case: the second diff is empty and the sequences are the
# target's.
sub settled {
  my ($label, $tag, $schema, $dbh, $to) = @_;
  my $again = eval { $schema->pg_deploy->diff };
  ok($again && !$again->has_changes, "$label: a second diff finds nothing to do")
    or diag $again ? $again->as_sql : $@;
  is_deeply(sequences_of($dbh), target_sequences($tag, $to),
    "$label: the sequences are those of the target installed whole");
}

# ---------------------------------------------------------------------------
# 1. A new table with a serial column
# ---------------------------------------------------------------------------
my %WIDTH = ( serial => 'integer', bigserial => 'bigint', smallserial => 'smallint' );
for my $type (qw( serial bigserial smallserial )) {
  my $label = "new table, $type";
  my $to = schema_class({}, Base => $BASE, Late => result_class(table => 'late', pk => ['id'], columns => [
    id => { data_type => $type, is_nullable => 0 }, v => { data_type => 'text', is_nullable => 1 } ]));
  my ($schema, $dbh, $diff) = upgraded("t110new$type", $label, schema_class({}, Base => $BASE), $to);
  SKIP: {
    skip "$label: no upgrade", 3 unless $schema;
    like($diff->as_sql, qr/CREATE SEQUENCE public\.late_id_seq AS \Q$WIDTH{$type}\E /,
      "$label: the diff creates the sequence, counting in $WIDTH{$type}");
    $dbh->do(q{INSERT INTO late (v) VALUES ('a')});
    is_deeply($dbh->selectcol_arrayref('SELECT id FROM late'), [1], "$label: the row got its id from the sequence");
    settled($label, "t110new$type", $schema, $dbh, $to);
  }
  $schema->storage->disconnect if $schema;
}

# ---------------------------------------------------------------------------
# 2. ADD COLUMN serial to a table with rows
# ---------------------------------------------------------------------------
{
  my $label = 'ADD COLUMN serial';
  my $from = schema_class({}, Base => $BASE, Grow => result_class(table => 'grow', columns => [
    v => { data_type => 'text', is_nullable => 1 } ]));
  my $to = schema_class({}, Base => $BASE, Grow => result_class(table => 'grow', columns => [
    v => { data_type => 'text', is_nullable => 1 }, n => { data_type => 'serial', is_nullable => 0 } ]));
  my ($schema, $dbh) = upgraded('t110add', $label, $from, $to,
    sub { $_[0]->do(q{INSERT INTO grow (v) VALUES ('a'), ('b')}) });
  SKIP: {
    skip "$label: no upgrade", 3 unless $schema;
    is_deeply($dbh->selectcol_arrayref('SELECT n FROM grow ORDER BY n'), [1, 2],
      "$label: the rows that were there are numbered from the sequence");
    $dbh->do(q{INSERT INTO grow (v) VALUES ('c')});
    is_deeply($dbh->selectcol_arrayref('SELECT n FROM grow ORDER BY n'), [1, 2, 3],
      "$label: and the next row goes on from there");
    settled($label, 't110add', $schema, $dbh, $to);
  }
  $schema->storage->disconnect if $schema;
}

# ---------------------------------------------------------------------------
# 3. A schema that is not public, and names that need their quotes
# ---------------------------------------------------------------------------
{
  my $label = 'schema auth';
  my %opt = ( pg_schemas => [qw( public auth )] );
  my $to = schema_class(\%opt, Base => $BASE, U => result_class(pg_schema => 'auth', table => 'users',
    pk => ['id'], columns => [ id => { data_type => 'serial', is_nullable => 0 } ]));
  my ($schema, $dbh, $diff) = upgraded('t110auth', $label, schema_class(\%opt, Base => $BASE), $to);
  SKIP: {
    skip "$label: no upgrade", 3 unless $schema;
    like($diff->as_sql, qr/ALTER SEQUENCE auth\.users_id_seq OWNED BY auth\.users\.id;/,
      "$label: the sequence is given to the column in auth");
    $dbh->do('INSERT INTO auth.users DEFAULT VALUES');
    is_deeply($dbh->selectcol_arrayref('SELECT id FROM auth.users'), [1], "$label: the row got its id");
    settled($label, 't110auth', $schema, $dbh, $to);
  }
  $schema->storage->disconnect if $schema;
}
{
  my $label = 'Mixed-Case names';
  my $to = schema_class({}, Base => $BASE, M => result_class(table => 'LateTab', pk => ['Id'], columns => [
    Id => { data_type => 'serial', is_nullable => 0 }, V => { data_type => 'text', is_nullable => 1 } ]));
  my ($schema, $dbh) = upgraded('t110mixed', $label, schema_class({}, Base => $BASE), $to);
  SKIP: {
    skip "$label: no upgrade", 3 unless $schema;
    $dbh->do(q{INSERT INTO "LateTab" ("V") VALUES ('a')});
    is_deeply($dbh->selectcol_arrayref('SELECT "Id" FROM "LateTab"'), [1], "$label: the row got its id");
    is_deeply([ sort keys %{ sequences_of($dbh) } ], ['public.LateTab_Id_seq'],
      "$label: the sequence is called what the default calls it");
    settled($label, 't110mixed', $schema, $dbh, $to);
  }
  $schema->storage->disconnect if $schema;
}

# ---------------------------------------------------------------------------
# 4. A plain column becomes serial
# ---------------------------------------------------------------------------
{
  my $label = 'plain column becomes serial';
  my $from = schema_class({}, Base => $BASE, G => result_class(table => 'grow', columns => [
    n => { data_type => 'integer', is_nullable => 0 } ]));
  my $to = schema_class({}, Base => $BASE, G => result_class(table => 'grow', columns => [
    n => { data_type => 'serial', is_nullable => 0 } ]));
  # integer is bigint here and serial is integer: the narrowing is released
  my ($schema, $dbh) = upgraded('t110plain', $label, $from, $to, undef, allow_destructive => 1);
  SKIP: {
    skip "$label: no upgrade", 3 unless $schema;
    $dbh->do('INSERT INTO grow DEFAULT VALUES');
    is_deeply($dbh->selectcol_arrayref('SELECT n FROM grow'), [1], "$label: the row got its number");
    settled($label, 't110plain', $schema, $dbh, $to);
  }
  $schema->storage->disconnect if $schema;
}

# ---------------------------------------------------------------------------
# 5. An identity column becomes serial: refused, and the way out
# ---------------------------------------------------------------------------
{
  my $label = 'identity becomes serial';
  my $from = schema_class({}, Base => $BASE, G => result_class(table => 'grow', columns => [
    n => { data_type => 'integer', is_nullable => 0, is_auto_increment => 1 } ]));
  my $to = schema_class({}, Base => $BASE, G => result_class(table => 'grow', columns => [
    n => { data_type => 'serial', is_nullable => 0 } ]));

  my @db = PrivatePgDatabase->create('t110ident');
  my $s1 = $from->connect(@db, @CONNECT);
  $s1->pg_deploy->install;
  $s1->storage->disconnect;

  my $schema = $to->connect(@db, @CONNECT);
  my $diff = eval { $schema->pg_deploy->diff };
  my $error = $@;
  ok(!$diff, "$label: the diff dies") or diag $diff && $diff->as_sql;
  like($error, qr/\Arefusing to diff: sequence public\.grow_n_seq /, "$label: with a refusal about the sequence");
  like($error, qr/identity sequence of column public\.grow\.n/, "$label: that names the column");
  my ($way_out) = $error =~ /^  (ALTER TABLE .* DROP IDENTITY;)$/m;
  is($way_out, 'ALTER TABLE public.grow ALTER COLUMN n DROP IDENTITY;', "$label: and the statement that settles it");

  SKIP: {
    skip "$label: no way out", 4 unless $way_out;
    my $dbh = $schema->storage->dbh;
    ok(eval { $dbh->do($way_out); 1 }, "$label: the server takes the way out") or diag $@;
    my $d = eval { $schema->pg_deploy->diff };
    ok($d, "$label: the diff is built after it") or diag $@;
    skip "$label: no diff", 2 unless $d;
    unlike($d->as_sql, qr/DROP IDENTITY/, "$label: and has no DROP IDENTITY left");
    # the identity column is bigint here and serial is integer: the narrowing is released
    ok(eval { $schema->pg_deploy->apply($d, allow_destructive => 1); 1 }, "$label: the upgrade runs") or diag $@;
    settled($label, 't110ident', $schema, $dbh, $to);
  }
  $schema->storage->disconnect;
}

# ---------------------------------------------------------------------------
# 6. serial becomes identity: the DROP DEFAULT stands ahead of the identity
# ---------------------------------------------------------------------------
{
  my $label = 'serial becomes identity';
  my $from = schema_class({}, Base => $BASE, G => result_class(table => 'grow', columns => [
    n => { data_type => 'serial', is_nullable => 0 } ]));
  my $to = schema_class({}, Base => $BASE, G => result_class(table => 'grow', columns => [
    n => { data_type => 'integer', is_nullable => 0, is_auto_increment => 1 } ]));
  my ($schema, $dbh) = upgraded('t110toident', $label, $from, $to);
  SKIP: {
    skip "$label: no upgrade", 2 unless $schema;
    $dbh->do('INSERT INTO grow DEFAULT VALUES');
    is_deeply($dbh->selectcol_arrayref('SELECT n FROM grow'), [1], "$label: the row got its number");
    my $again = eval { $schema->pg_deploy->diff };
    ok($again && !$again->has_changes, "$label: a second diff finds nothing to do")
      or diag $again ? $again->as_sql : $@;
  }
  $schema->storage->disconnect if $schema;
}

# ---------------------------------------------------------------------------
# 7. A sequence no column owns, called by a default
# ---------------------------------------------------------------------------
{
  my $label = 'sequence of its own';
  my $to = schema_class({}, Base => $BASE, T => result_class(table => 'ticket',
    columns => [ v => { data_type => 'text', is_nullable => 1 } ],
    extra => [
      'CREATE SEQUENCE ticket_no_seq START 1000 INCREMENT 5',
      q{ALTER TABLE ticket ADD COLUMN no bigint NOT NULL DEFAULT nextval('ticket_no_seq')},
    ]));
  my ($schema, $dbh) = upgraded('t110own', $label, schema_class({}, Base => $BASE), $to);
  SKIP: {
    skip "$label: no upgrade", 2 unless $schema;
    $dbh->do(q{INSERT INTO ticket (v) VALUES ('a'), ('b')});
    is_deeply($dbh->selectcol_arrayref('SELECT no FROM ticket ORDER BY no'), [1000, 1005],
      "$label: the sequence counts as the target says");
    settled($label, 't110own', $schema, $dbh, $to);
  }
  $schema->storage->disconnect if $schema;
}

done_testing;
