use strict;
use warnings;
use Test::More;

# LIVE half of t/106 (karr k106), on the real server: foreign keys that meet in
# one name, and a composite foreign key over a primary key (b, a).
#
# WHY IT MATTERS. An install must work for the schemas main installs, and an
# upgrade must end in the very same constraints as the install, or the next
# diff has something to say for ever. What this file claims, on MySQL and on
# MariaDB:
#   1. two belongs_to over one key to one target are ONE constraint in the
#      database;
#   2. table a_b column c and table a column b_c (one name a_b_c_fk) both
#      exist after the install, under two names, and an upgrade out of an
#      empty database and an upgrade that adds them to existing tables end in
#      the same constraints, the diff afterwards empty;
#   3. one column that references two targets: the same;
#   4. a primary key (b, a) with a foreign key over both columns installs (the
#      server takes the referenced list only in the order of the key) and the
#      upgrade ends alike, the diff empty.
#
# Gated like the other live tests; works in a database of its own (t/96).

my ($dsn, $user, $pass) = @ENV{ map { "DBIO_TEST_MYSQL_${_}" } qw/DSN USER PASS/ };

plan skip_all => 'Set $ENV{DBIO_TEST_MYSQL_DSN}, _USER and _PASS to run this test'
  unless $dsn && $user;

use DBI;
use DBIO::MySQL::Deploy;

my $DB = "dbio_k106c_$$";
my $raw = DBI->connect($dsn, $user, $pass, { AutoCommit => 1, RaiseError => 1, PrintError => 0 });

sub drop_database { local $raw->{Warn} = 0; $raw->do("DROP DATABASE IF EXISTS `$DB`") }
END { if ($raw) { local ($@, $?); eval { drop_database() } } }

unless (eval { drop_database(); $raw->do("CREATE DATABASE `$DB`"); 1 }) {
  my $why = "$@";
  undef $raw;
  plan skip_all => "this account may not create a database of its own: $why";
}
note sprintf 'server %s, database %s', scalar $raw->selectrow_array('SELECT VERSION()'), $DB;

my $n = 0;
# %spec: table => { cols, pk, rels => [ [ name, target, cond ] ] }; $fk = 0
# builds the same tables without the foreign keys (the "before" of an upgrade).
sub schema_for {
  my ($spec, $fk) = @_;
  my $ns = 'K106CollLive::V' . ++$n;
  eval "package $ns; use DBIO 'Schema'; __PACKAGE__->load_components('MySQL'); 1" or die $@;
  my %class = map { $_ => "${ns}::Result::" . join '', map { ucfirst } split /_/, $_ } keys %$spec;
  for my $t (sort keys %$spec) {
    my $class = $class{$t};
    eval "package $class; use DBIO 'Core', -mysql; 1" or die $@;
    $class->table($t);
    my %is_pk = map { $_ => 1 } @{ $spec->{$t}{pk} };
    $class->add_columns(map { $_ => { data_type => 'integer', $is_pk{$_} ? () : (is_nullable => 1) } } @{ $spec->{$t}{cols} });
    $class->set_primary_key(@{ $spec->{$t}{pk} });
  }
  for my $t (sort keys %$spec) {
    $class{$t}->belongs_to($_->[0] => $class{ $_->[1] }, $_->[2], { ($fk ? () : (is_foreign_key_constraint => 0)) })
      for @{ $spec->{$t}{rels} // [] };
    $ns->register_class($t => $class{$t});
  }
  return $ns->connect($dsn, $user, $pass, { on_connect_do => ["USE `$DB`"] });
}
sub fresh { drop_database(); $raw->do("CREATE DATABASE `$DB`"); $raw->do("USE `$DB`") }

# Every foreign key column pair of the database: name, table, column, target, target column, position.
sub state {
  return join "\n", map { join ' ', map { $_ // '' } @$_ } @{ $raw->selectall_arrayref(
    'SELECT CONSTRAINT_NAME, TABLE_NAME, COLUMN_NAME, REFERENCED_TABLE_NAME, REFERENCED_COLUMN_NAME, ORDINAL_POSITION '
  . 'FROM information_schema.KEY_COLUMN_USAGE WHERE TABLE_SCHEMA = ? AND REFERENCED_TABLE_NAME IS NOT NULL '
  . 'ORDER BY CONSTRAINT_NAME, ORDINAL_POSITION', undef, $DB) };
}
sub names { return [ sort keys %{ { map { $_ => 1 } map { (split ' ')[0] } split /\n/, state() } } ] }
sub diff_is_empty {
  my ($schema, $what) = @_;
  my $d = eval { DBIO::MySQL::Deploy->new(schema => $schema)->diff };
  ok $d && !$d->has_changes, "$what: the next diff is empty" or diag $@ // join "\n", map { $_->as_sql } @{ $d->operations };
}
sub deploy {
  my ($how, $spec, $fk) = @_;
  my $s = schema_for($spec, $fk);
  my $ok = eval { DBIO::MySQL::Deploy->new(schema => $s)->$how; 1 };
  my $err = $@;
  return ($s, $ok, $err);
}

my $P = { cols => ['id'], pk => ['id'] };
my %case = (
  'two belongs_to, one foreign key' => [
    { p => $P, c => { cols => [qw/id pid/], pk => ['id'], rels => [
        [ parent => p => { 'foreign.id' => 'self.pid' } ], [ owner => p => { 'foreign.id' => 'self.pid' } ] ] } },
    1 ],
  'a_b.c and a.b_c meet in one name' => [
    { p => $P,
      a   => { cols => [qw/id b_c/], pk => ['id'], rels => [ [ r => p => { 'foreign.id' => 'self.b_c' } ] ] },
      a_b => { cols => [qw/id c/],   pk => ['id'], rels => [ [ r => p => { 'foreign.id' => 'self.c' } ] ] } },
    2 ],
  'one column to two targets' => [
    { p1 => $P, p2 => $P,
      c => { cols => [qw/id pid/], pk => ['id'], rels => [
        [ one => p1 => { 'foreign.id' => 'self.pid' } ], [ two => p2 => { 'foreign.id' => 'self.pid' } ] ] } },
    2 ],
  'primary key (b, a), composite foreign key' => [
    { q => { cols => [qw/b a/], pk => [qw/b a/] },
      r => { cols => [qw/id xb ya/], pk => ['id'], rels => [
        [ q => q => { 'foreign.b' => 'self.xb', 'foreign.a' => 'self.ya' } ] ] } },
    1 ],
);

for my $name (sort keys %case) {
  my ($spec, $count) = @{ $case{$name} };
  subtest $name => sub {
    fresh();
    my ($inst, $ok, $err) = deploy('install', $spec, 1);
    ok $ok, 'install takes it' or diag $err;
    is scalar(@{ names() }), $count, "... $count constraint(s) in the database";
    my $installed = state();
    diff_is_empty($inst, 'install');
    $inst->storage->disconnect;

    fresh();
    my ($up, $ok2, $err2) = deploy('upgrade', $spec, 1);
    ok $ok2, 'upgrade out of an empty database' or diag $err2;
    is state(), $installed, '... ends in the same foreign keys as the install';
    diff_is_empty($up, 'upgrade out of an empty database');
    $up->storage->disconnect;

    fresh();
    my ($before) = deploy('install', $spec, 0);
    $before->storage->disconnect;
    is state(), '', 'upgrade adding them: starts without';
    my ($add, $ok3, $err3) = deploy('upgrade', $spec, 1);
    ok $ok3, '... the upgrade adds them' or diag $err3;
    is state(), $installed, '... same foreign keys as the install';
    diff_is_empty($add, 'upgrade adding them');
    $add->storage->disconnect;
  };
}

done_testing;
