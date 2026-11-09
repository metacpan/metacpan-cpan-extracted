use strict;
use warnings;

use Test::More;

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_PG_$_" } qw(DSN USER PASS)};

plan skip_all => 'Set DBIO_TEST_PG_DSN, _USER and _PASS to run this test'
  unless $dsn;

use DBIO::Core ();
use DBIO::Schema ();
use DBIO::PostgreSQL::Deploy;
use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;
use PrivatePgDatabase;

# A server that is not there fails the file, with a plan (karr k113).
LiveServer->require_server;

# karr k152 (core k399): apply is the base's, and the guard runs ahead of the
# first statement.
#
# WHY it exists: an upgrade that drops a table, or changes a column's type so
# that stored values may change, ran without a question. Now it runs only when
# released with allow_destructive. A type change that keeps every value
# (integer to bigint) is not asked about; dry_run executes nothing and the
# refusal leaves the database as it was, an additive change ahead of the risky
# one included.

my $n = 0;

# The schema class whose table t has id, v of the given type, and the nullable
# new column a (an additive change, ahead of the type change in the diff).
sub target {
  my ($type) = @_;
  my $result = 'T196::Result::R' . ++$n;
  eval qq{
    package $result;
    use base 'DBIO::Core';
    __PACKAGE__->load_components('PostgreSQL::Result');
    1;
  } or die $@;
  $result->table('t');
  $result->add_columns(
    id => { data_type => 'bigint', is_nullable => 0 },
    a  => { data_type => 'text', is_nullable => 1 },
    v  => { data_type => $type, is_nullable => 1 },
  );
  $result->set_primary_key('id');

  my $class = 'T196::Schema::S' . ++$n;
  no strict 'refs';
  @{"${class}::ISA"} = ('DBIO::Schema');
  $class->load_components('PostgreSQL');
  $class->pg_schemas('public');
  $class->register_class(T => $result);
  return $class;
}

# A private database whose table t has id and v of the type $from with a row.
sub prepared {
  my ($tag, $from, $to, $value) = @_;
  my @db  = PrivatePgDatabase->create($tag);
  my $dbh = LiveServer->control_dbh(login => \@db, attrs => { PrintWarn => 0 });
  $dbh->do("CREATE TABLE t (id bigint PRIMARY KEY, v $from)");
  $dbh->do('INSERT INTO t VALUES (1, ?)', undef, $value);
  $dbh->disconnect;
  return target($to)->connect(@db, { PrintError => 0, PrintWarn => 0 });
}

sub state {
  my ($schema) = @_;
  my $dbh = $schema->storage->dbh;
  return join ' ', map { $_->[0] . ':' . $_->[1] } @{ $dbh->selectall_arrayref(
    q{SELECT a.attname, format_type(a.atttypid, a.atttypmod) FROM pg_attribute a
      WHERE a.attrelid = 't'::regclass AND a.attnum > 0 AND NOT a.attisdropped ORDER BY a.attnum}) };
}

# --- integer to bigint: released by nothing, asked of nobody ------------------
{
  my $schema = prepared('t196a', 'integer', 'bigint', 5);
  my $deploy = $schema->pg_deploy;
  my $diff = $deploy->diff;
  ok $diff->has_changes, 'integer to bigint: the diff has changes';
  is scalar(() = $diff->destructive_operations), 0, '... nothing the guard asks about';
  ok eval { $deploy->apply($diff); 1 }, '... apply runs without allow_destructive' or diag $@;
  is state($schema), 'id:bigint v:bigint a:text', '... the column is bigint, the new column is there';
  $schema->storage->disconnect;
}

# --- bigint to integer: asked, before the first statement ---------------------
{
  my $schema = prepared('t196b', 'bigint', 'int4', 5);
  my $deploy = $schema->pg_deploy;
  my $diff = $deploy->diff;
  my $before = state($schema);
  ok !eval { $deploy->apply($diff); 1 }, 'bigint to integer: apply without allow_destructive dies';
  like $@, qr/allow_destructive/, '... naming allow_destructive';
  like $@, qr/column: public\.t\.v/, '... and the column';
  unlike $@, qr/\b5\b/, '... and no value';
  is state($schema), $before, '... and no statement ran: not even the additive new column';

  my $seen = $deploy->apply($diff, dry_run => 1);
  ok $seen && $seen == $diff, 'dry_run returns the diff';
  is state($schema), $before, '... and executes nothing, the guard asks nothing of it';

  ok eval { $deploy->apply($diff, allow_destructive => 1); 1 }, 'with allow_destructive the diff runs' or diag $@;
  is state($schema), 'id:bigint v:integer a:text', '... bigint is integer, a is there';
  $schema->storage->disconnect;
}

# --- the attribute releases as well, and upgrade passes the argument on -------
{
  my $schema = prepared('t196c', 'bigint', 'int2', 7);
  my $deploy = $schema->pg_deploy;
  ok !eval { $deploy->upgrade; 1 }, 'bigint to smallint: upgrade without release dies';
  like $@, qr/allow_destructive/, '... naming allow_destructive';
  ok eval { $deploy->upgrade(allow_destructive => 1); 1 }, 'upgrade(allow_destructive => 1) runs' or diag $@;
  is state($schema), 'id:bigint v:smallint a:text', '... and the type is changed';
  $schema->storage->disconnect;
}

done_testing;
