use strict;
use warnings;
use Test::More;

use Scalar::Util ();
use DBIO::Firebird::Storage;
use DBIO::Firebird::Storage::InterBase;
use DBIO::Firebird::Storage::ODBC;

# OFFLINE (karr k37).
#
# WHY: DBD::Firebird destroys every statement of a connection when it commits
# after DDL, and on every hard rollback inside a transaction. The Perl handles
# stay in DBI's statement cache, and prepare_cached keeps handing them out. Such
# a handle does not fail: a SELECT executes and returns no row, an INSERT or
# UPDATE executes and writes nothing. So the native storages must not hand a
# destroyed handle on -- _prepare_sth is the one place every statement of the
# storage comes through.
#
# What this file claims about that method, on the two native storage classes:
#   1. a prepared handle in the cache is handed out as it is -- the cache stays
#      a cache -- and asking it whether it is alive binds nothing;
#   2. a destroyed handle is not handed out; a newly prepared one is;
#   3. the cache is emptied then, not only of that one entry, and the destroyed
#      handle is let go BEFORE its replacement is prepared. Both are about
#      DBD::Firebird's own list of statements: the second destruction of a
#      handle it has already destroyed empties that list, and a statement that
#      is alive and not on the list later keeps its table "in use" for a DROP;
#   4. the replacement is not asked again: a DBD answering "dead" for every
#      handle costs one extra prepare per statement, not a loop;
#   5. with disable_sth_caching nothing comes out of a cache, so nothing is
#      asked and nothing is thrown away;
#   6. the ODBC storage does none of this -- it is a fact about the DBD's API,
#      not about the engine (ADR 0010).
#
# THE SUBSTITUTIONS: a stand-in database handle whose prepare_cached keeps its
# handles by SQL as DBI's does, and a stand-in statement handle whose
# bind_param answers as dbd_bind_ph of DBD::Firebird 1.39 does: false once the
# statement is destroyed, true without binding for a placeholder number past
# the last one. That the real DBD answers this way is the claim of
# t/23-statement-cache-ddl-live.t, not of this file.

# what happened, in order: [ prepare_cached | prepare | destroy => sql, serial ]
our @LOG;

{
  package T::Sth;

  my $serial = 0;

  sub new {
    my ($class, $sql, $alive) = @_;
    return bless {
      Statement => $sql, NUM_OF_PARAMS => ($sql =~ tr/?//),
      alive => $alive, asked => 0, bound => [], serial => ++$serial,
    }, $class;
  }

  # dbd_bind_ph
  sub bind_param {
    my ($self, $number, $value) = @_;
    $self->{asked}++;
    return 0 unless $self->{alive};
    return 1 if $number > $self->{NUM_OF_PARAMS};
    push @{ $self->{bound} }, $number;
    return 1;
  }

  sub DESTROY { push @main::LOG, [ destroy => @{ $_[0] }{qw( Statement serial )} ] }
}

{
  package T::Dbh;

  # $alive: what a handle prepared from now on answers
  sub new {
    my ($class, %args) = @_;
    return bless {
      CachedKids => {}, Driver => { Name => 'Firebird' }, alive => 1, %args,
    }, $class;
  }

  sub prepare {
    my ($self, $sql) = @_;
    my $sth = T::Sth->new($sql, $self->{alive});
    push @main::LOG, [ prepare => $sql, $sth->{serial} ];
    return $sth;
  }

  sub prepare_cached {
    my ($self, $sql) = @_;
    return $self->{CachedKids}{$sql} if $self->{CachedKids}{$sql};
    my $sth = $self->{CachedKids}{$sql} = T::Sth->new($sql, $self->{alive});
    push @main::LOG, [ prepare_cached => $sql, $sth->{serial} ];
    return $sth;
  }

  sub errstr { undef }

  # what DBD::Firebird does to every statement of the connection on a commit
  # after DDL: destroyed, and left where it is
  sub destroy_statements { $_->{alive} = 0 for values %{ $_[0]{CachedKids} } }
}

my $SELECT = 'SELECT "name" FROM "artist" WHERE "artistid" = ?';
my $UPDATE = 'UPDATE "artist" SET "name" = ? WHERE "artistid" = ?';

sub events { [ map { "$_->[0] $_->[2]" } @LOG ] }

for my $class (qw( DBIO::Firebird::Storage DBIO::Firebird::Storage::InterBase )) {

  # --- 1. a prepared handle stays in the cache --------------------------------
  {
    local @LOG;
    my $storage = $class->new(undef);
    my $dbh     = T::Dbh->new;

    my $first  = $storage->_prepare_sth($dbh, $SELECT);
    my $second = $storage->_prepare_sth($dbh, $SELECT);

    is Scalar::Util::refaddr($second), Scalar::Util::refaddr($first),
      "$class: a prepared handle comes out of the cache again -- the cache is still one";
    is scalar( grep { $_->[0] =~ /^prepare/ } @LOG ), 1, '... prepared once';
    is_deeply $first->{bound}, [],
      '... and asking whether it is alive bound no placeholder of the statement';
    ok eval { $storage->_sth_is_alive($first) }, '... which _sth_is_alive calls alive'
      or diag $@;
  }

  # --- 2. + 3. a destroyed handle is not handed out ---------------------------
  {
    local @LOG;
    my $storage = $class->new(undef);
    my $dbh     = T::Dbh->new;

    my %dead = map { $_ => $storage->_prepare_sth($dbh, $_)->{serial} } $SELECT, $UPDATE;
    $dbh->destroy_statements;
    @LOG = ();

    my $sth = $storage->_prepare_sth($dbh, $SELECT);

    ok $sth->{alive}, "$class: after the DBD destroyed its statements, the handle handed out is a prepared one";
    isnt $sth->{serial}, $dead{$SELECT}, '... a new one, not the destroyed one';
    is Scalar::Util::refaddr($dbh->{CachedKids}{$SELECT}), Scalar::Util::refaddr($sth),
      '... which is the one in the cache now';
    ok !exists $dbh->{CachedKids}{$UPDATE},
      '... and the other statement left the cache with it: every handle of the '
    . 'connection was destroyed, and each of them destroyed once more later '
    . 'would take the new handle off the DBD\'s list';

    is_deeply [ map { $_->[0] } @LOG ], [ qw( destroy destroy prepare_cached ) ],
      '... both destroyed handles were let go before the replacement was prepared'
      or diag explain \@LOG;
    is $sth->{asked}, 0, '... and the replacement was not asked whether it is alive';
  }

  # --- 4. no loop when every handle answers "dead" ----------------------------
  {
    local @LOG;
    my $storage = $class->new(undef);
    my $dbh     = T::Dbh->new(alive => 0);

    my $sth = $storage->_prepare_sth($dbh, $SELECT);

    my ($second, $first) = ($sth->{serial}, $sth->{serial} - 1);

    is_deeply events(), [ "prepare_cached $first", "destroy $first", "prepare_cached $second" ],
      "$class: a DBD that calls every handle dead costs one more prepare, and the second handle is handed out"
      or diag explain \@LOG;
    is $sth->{asked}, 0, '... unasked';
  }

  # --- 5. disable_sth_caching -------------------------------------------------
  {
    local @LOG;
    my $storage = $class->new(undef);
    my $dbh     = T::Dbh->new;

    my $cached = $storage->_prepare_sth($dbh, $UPDATE);
    $dbh->destroy_statements;
    $dbh->{alive} = 0;                  # even a handle that would answer "dead"
    $storage->disable_sth_caching(1);
    @LOG = ();

    my $sth = $storage->_prepare_sth($dbh, $SELECT);

    is_deeply [ map { $_->[0] } @LOG ], [ 'prepare' ],
      "$class: with disable_sth_caching the statement is prepared once, outside the cache";
    is $sth->{asked}, 0, '... and not asked: it cannot have come out of a cache';
    is Scalar::Util::refaddr($dbh->{CachedKids}{$UPDATE}), Scalar::Util::refaddr($cached),
      '... and the cache is left alone';
  }
}

# --- 6. not on the ODBC transport ---------------------------------------------
{
  local @LOG;
  my $storage = DBIO::Firebird::Storage::ODBC->new(undef);
  my $dbh     = T::Dbh->new;

  my $first = $storage->_prepare_sth($dbh, $SELECT);
  $dbh->destroy_statements;
  my $second = $storage->_prepare_sth($dbh, $SELECT);

  is Scalar::Util::refaddr($second), Scalar::Util::refaddr($first),
    'the ODBC storage hands out what DBI\'s cache holds: what DBD::Firebird '
  . 'does to its statements is not a fact about DBD::ODBC';
  is $first->{asked}, 0, '... without asking the handle anything';
  ok !DBIO::Firebird::Storage::ODBC->can('_sth_is_alive'),
    '... and the question is not in its ancestry';
}

done_testing;
