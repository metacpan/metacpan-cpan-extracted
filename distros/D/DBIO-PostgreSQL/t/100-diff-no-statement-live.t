use strict;
use warnings;

use Test::More;
use Test::Exception;

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_PG_$_" } qw(DSN USER PASS)};

plan skip_all => 'Set DBIO_TEST_PG_DSN, _USER and _PASS to run this test'
  unless $dsn;

use DBIO::PostgreSQL::Diff;
use DBIO::PostgreSQL::Diff::Function;
use DBIO::PostgreSQL::Diff::Index;
use DBIO::PostgreSQL::Diff::Trigger;
use DBIO::PostgreSQL::Introspect;
use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;
use PrivatePgDatabase;

# A server that is not there fails the file, with a plan (karr k113).
LiveServer->require_server;

# LIVE test for karr k120 (1): the one way the catalog itself hands out a
# function, a trigger or an index without a definition.
#
# WHY it exists: t/100-diff-no-statement.t pins that the diff refuses such an
# object instead of writing a comment or a placeholder for it, with models
# built by hand. Whether a server ever produces such a model, and what is
# then still in it, only a server says -- and the refusal names that cause.
#
# pg_get_functiondef, pg_get_triggerdef and pg_get_indexdef look the object
# up apart from the snapshot of the statement that calls them. A session that
# reads the catalog under an older snapshot still finds the row of an object
# another session has dropped since, with its name -- and gets NULL for its
# definition. REPEATABLE READ makes that window as wide as the transaction,
# which is what makes it testable.
#
# Four claims:
#
#  1. the model such a session reads has the dropped function, trigger and
#     index, each without a definition -- the index still with its column and
#     marked unique, which is what used to be written as a plain index;
#  2. the diff refuses every one of them, naming the object, the catalog
#     function its definition comes from and how it came to have none;
#  3. reading the model again, as the refusal says, gives a model without
#     them, and nothing in it lacks a definition;
#  4. a view is no such case, which is why the refusal for a view does not
#     name this cause: pg_get_viewdef raises an error for a view that is
#     gone, and the reading of the model dies of it.
#
# Everything happens in a database of this file's own (karr k81).

my @private = PrivatePgDatabase->create('t100');
my $reader  = LiveServer->control_dbh(login => \@private, attrs => { PrintWarn => 0 });
my $other   = LiveServer->control_dbh(login => \@private, attrs => { PrintWarn => 0 });

$other->do($_) for
  q{CREATE FUNCTION trg_fn() RETURNS trigger LANGUAGE plpgsql AS $$BEGIN RETURN NEW; END$$},
  q{CREATE FUNCTION f_gone() RETURNS integer LANGUAGE sql AS 'SELECT 1'},
  q{CREATE TABLE t (id integer PRIMARY KEY, m integer)},
  q{CREATE UNIQUE INDEX t_gone_idx ON t (m) WHERE m > 0},
  q{CREATE TRIGGER t_gone_trg BEFORE INSERT ON t FOR EACH ROW EXECUTE FUNCTION trg_fn()};

sub model_of {
  my ($dbh) = @_;
  return DBIO::PostgreSQL::Introspect->new(dbh => $dbh, schema_filter => ['public'])->model;
}

# A transaction of the reader with its snapshot taken, while the other
# session drops something: what the reader's model is then.
sub model_under_older_snapshot {
  my (@drop) = @_;
  $reader->begin_work;
  $reader->do('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ');
  $reader->selectrow_array('SELECT count(*) FROM pg_catalog.pg_class');
  $other->do($_) for @drop;

  my $model = eval {
    # Introspect::Functions builds the key of a function from its identity
    # arguments, and the catalog has none for a function that is gone
    # either: perl warns about the undef. That is the introspection's to
    # answer (noted on the card), not what is tested here.
    local $SIG{__WARN__} = sub {
      return note "Introspect warned: $_[0]" if $_[0] =~ /uninitialized/;
      warn @_;
    };
    model_of($reader);
  };
  my $error = $@;
  $reader->rollback;
  return ($model, $error);
}

my ($stale, $died) = model_under_older_snapshot(
  'DROP FUNCTION f_gone()',
  'DROP TRIGGER t_gone_trg ON t',
  'DROP INDEX t_gone_idx',
);
is $died, '', 'the reader gets a model'
  or BAIL_OUT('no model to test with');

# --- 1. what the reader got -------------------------------------------------

my ($f_key) = grep { /f_gone/ } keys %{ $stale->{functions} };
my $function = $stale->{functions}{ $f_key // '' };
my $trigger  = $stale->{triggers}{'public.t'}{t_gone_trg};
my $index    = $stale->{indexes}{'public.t'}{t_gone_idx};

ok $function && !defined $function->{definition},
  'the reader has the dropped function, without a definition';
ok $trigger && !defined $trigger->{definition},
  'the reader has the dropped trigger, without a definition';
ok $index && !defined $index->{definition},
  'the reader has the dropped index, without a definition';
is_deeply [ @{ $index // {} }{qw( is_unique columns predicate )} ], [ 1, ['m'], '(m > 0)' ],
  '... but still with its column, as unique and with its predicate: a plain CREATE INDEX was written from the first of the three';

# --- 2. the diff refuses each of them ---------------------------------------

my %kept = ('public.t' => $stale->{tables}{'public.t'});

throws_ok { DBIO::PostgreSQL::Diff::Function->diff({}, { $f_key => $function }) }
  qr/\Arefusing to diff: function \Q$f_key\E is in the target and not in the database/,
  'the function is refused, by name';
like $@, qr/pg_get_functiondef/, '... naming where its definition would have come from';
like $@, qr/another session dropped while the model was read/, '... and how it came to have none';

throws_ok { DBIO::PostgreSQL::Diff::Trigger->diff({}, { 'public.t' => { t_gone_trg => $trigger } }, \%kept, \%kept) }
  qr/\Arefusing to diff: trigger t_gone_trg on public\.t is in the target and not in the database/,
  'the trigger is refused, by name and table';
like $@, qr/pg_get_triggerdef/, '... naming where its definition would have come from';
like $@, qr/another session dropped while the model was read/, '... and how it came to have none';

throws_ok { DBIO::PostgreSQL::Diff::Index->diff({}, { 'public.t' => { t_gone_idx => $index } }, \%kept, \%kept) }
  qr/\Arefusing to diff: index t_gone_idx on public\.t is in the target and not in the database/,
  'the index is refused, by name and table -- its column in the model or not';
like $@, qr/pg_get_indexdef/, '... naming where its definition would have come from';
like $@, qr/another session dropped while the model was read/, '... and how it came to have none';

# The whole diff, built as Deploy->diff builds it: nothing comes out of it.
{
  my $diff = DBIO::PostgreSQL::Diff->new(source => { schemas => { public => {} } }, target => $stale);
  throws_ok { $diff->operations } qr/\Arefusing to diff: /,
    'a diff towards that model dies when it builds its operations';
  like $@, qr/No statement was generated\./, '... and says that nothing was generated';
  like $@, qr/Read the target model again and diff again\./, '... and what to do';
}

# --- 3. the way out the refusal names ---------------------------------------

{
  my $fresh = model_of($reader);
  is_deeply [ grep { /gone/ } keys %{ $fresh->{functions} },
              map { keys %{ $fresh->{$_}{'public.t'} // {} } } qw( triggers indexes ) ],
    [], 'read again, the model does not have what was dropped';

  my @without = grep { !defined $fresh->{functions}{$_}{definition} } keys %{ $fresh->{functions} };
  for my $section (@{$fresh}{qw( triggers indexes )}) {
    for my $on (keys %$section) {
      push @without, grep { !defined $section->{$on}{$_}{definition} } keys %{ $section->{$on} };
    }
  }
  is_deeply \@without, [], '... and nothing in it lacks a definition';

  my $diff = DBIO::PostgreSQL::Diff->new(source => { schemas => { public => {} } }, target => $fresh);
  lives_ok { $diff->operations } 'a diff towards that model is built';
  is_deeply [ grep { !/\S/ || /\A\s*--/ } map { $_->as_sql } @{ $diff->operations } ], [],
    '... and every operation of it has a statement';
}

# --- 4. a view that is gone -------------------------------------------------

{
  $other->do('CREATE VIEW v_gone AS SELECT id FROM t');
  my ($model, $error) = model_under_older_snapshot('DROP VIEW v_gone');
  is $model, undef, 'with a view dropped under it, the reader gets no model';
  like $error, qr/could not open relation with OID/,
    '... the reading dies of the error pg_get_viewdef raises';
}

$_->disconnect for $reader, $other;

done_testing;
