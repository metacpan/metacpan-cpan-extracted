use strict;
use warnings;

use Test::More;

use DBI;
use DBIO::Deploy::Base::TempDatabase;

# karr k364. A DeploymentHandler upgrade runs inside a txn_scope_guard, and the
# diff of a temp-database driver creates and drops a database through the
# handle of the storage. CREATE/DROP DATABASE may not stand in a transaction,
# so the driver's _create_temp_db ends the open one and switches the handle to
# AutoCommit; seen live on PostgreSQL, the handle stayed there, and the guard's
# commit then reached a connection with AutoCommit on ("commit ineffective with
# AutoCommit enabled") after the upgrade had been committed early.
#
# What this file claims:
#   1. While the storage holds a transaction, the temp database is created and
#      dropped on a connection of its own, AutoCommit on, never on the
#      storage's handle -- that handle is not touched, so the transaction of
#      the caller is neither ended nor left changed.
#   2. Outside a transaction the storage's handle is used as ever.
#   3. The extra connection is closed again, on success and when the create
#      fails, and a failed create is raised.
#
# Substitution: DBD::Sponge stands in for the database; the driver class
# records which handle it is handed. No database, no real DBD behaviour -- the
# claim is which handle the statements run on.

{
  package T::Storage;
  sub new { my ($c, %a) = @_; bless {%a}, $c }
  sub storage { $_[0] }
  sub transaction_depth { $_[0]{depth} }
  sub _dbh { $_[0]{dbh} }
  sub _dbi_connect_info { [ 'dbi:Sponge:', 'u', 'p', {} ] }

  package T::Deploy;
  use base 'DBIO::Deploy::Base::TempDatabase';
  our (@calls, $fail_create);
  sub schema { $_[0]{schema} }
  sub _dbh   { $_[0]{schema}->_dbh }
  sub _create_temp_db {
    my ($self, $dbh) = @_;
    die "create failed\n" if $fail_create;
    push @calls, [ create => $dbh ];
    return 'tmp364';
  }
  sub _drop_temp_db {
    my ($self, $dbh, $name) = @_;
    push @calls, [ drop => $dbh ];
  }
  sub _deploy_and_introspect_temp { { model => 1 } }
}

sub build {
  my ($depth) = @_;
  # AutoCommit is on without a transaction (an off one is a transaction too,
  # k365); in a transaction it is off
  my $live = bless({ AutoCommit => $depth ? 0 : 1, Active => 1 }, 'T::Live');
  my $storage = T::Storage->new(depth => $depth, dbh => $live);
  my $deploy = T::Deploy->new(schema => $storage);
  @T::Deploy::calls = ();
  local $T::Deploy::fail_create;
  my $model = $deploy->_build_target_model;
  return ($live, $model, [@T::Deploy::calls]);
}

# the Sponge handle of the live connection is given Active, so a disconnect of
# the extra one shows
my @opened;
{
  no warnings 'redefine';
  my $orig = \&DBI::connect;
  *DBI::connect = sub { my $h = $orig->(@_); push @opened, $h if $h; $h };
}

{
  @opened = ();
  my ($live, $model, $calls) = build(1);
  is_deeply $model, { model => 1 }, 'in a transaction: the model comes back';
  is scalar(@$calls), 2, 'in a transaction: one create, one drop';
  for my $call (@$calls) {
    my ($what, $dbh) = @$call;
    isnt $dbh, $live, "in a transaction: $what does not run on the storage's handle";
  }
  ok $calls->[0][1]{AutoCommit}, 'in a transaction: ... but on one with AutoCommit on';
  is $calls->[0][1], $calls->[1][1], 'in a transaction: create and drop share that connection';
  ok !$calls->[0][1]{Active}, 'in a transaction: ... which is closed again afterwards';
  ok $live->{Active}, 'in a transaction: the storage\'s handle is left open';
  ok !$live->{AutoCommit}, 'in a transaction: ... and as it was (AutoCommit off)';
}

{
  @opened = ();
  my ($live, undef, $calls) = build(0);
  is $_->[1], $live, "outside a transaction: $_->[0] runs on the storage's handle" for @$calls;
  is scalar(grep { $_ != $live } @opened), 0, 'outside a transaction: no extra connection';
}

{
  @opened = ();
  my $live = bless({ AutoCommit => 0, Active => 1 }, 'T::Live');
  my $deploy = T::Deploy->new(schema => T::Storage->new(depth => 1, dbh => $live));
  local $T::Deploy::fail_create = 1;
  my $ok = eval { $deploy->_build_target_model; 1 };
  like "$@", qr/create failed/, 'a failed create is raised';
  my @extra = grep { $_ != $live } @opened;
  is scalar(@extra), 1, 'a failed create: the extra connection was opened ...';
  ok !$extra[0]{Active}, '... and is closed again';
}

done_testing;
