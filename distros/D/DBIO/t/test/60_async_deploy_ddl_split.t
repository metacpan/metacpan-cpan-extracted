use strict;
use warnings;
use Test::More;

use DBIO::Test::Future ();
use DBIO::Storage::Async;

# deploy_async cuts its DDL with the same splitter the sync path uses
# (DBIO::Deploy::Base::_split_ddl): it reads parenthesis depth and the SQL
# dialect the owning storage declares through _ddl_sql_dialect (karr k332).
# Driven through a fake transport -- no event loop, no database.

{
  package Test::SplitPool;
  sub new { bless { available => 1 }, shift }
  sub acquire     { DBIO::Test::Future->done('CONN') }
  sub acquire_txn { DBIO::Test::Future->done('CONN') }
  sub release     { 1 }
  sub available   { $_[0]->{available} }
  sub shutdown    { $_[0]->{available} = 0 }
}

{
  package Test::SplitOwner;
  sub new { bless { txn => $_[1], dialect => $_[2] }, $_[0] }
  sub _use_transactional_ddl { $_[0]->{txn} }
  sub _ddl_sql_dialect       { $_[0]->{dialect} }
}

{
  package Test::SplitBackend;
  use base 'DBIO::Storage::Async';

  sub new {
    my ($class, %o) = @_;
    my $self = $class->SUPER::new(undef);
    $self->{captured} = [];
    $self->{ddl}      = $o{ddl};
    $self->{_owner}   = Test::SplitOwner->new($o{txn}, $o{dialect});
    $self->_owner_storage($self->{_owner});
    return $self;
  }
  sub future_class        { 'DBIO::Test::Future' }
  sub pool                { $_[0]->{pool} ||= Test::SplitPool->new }
  sub _install_ddl        { $_[0]->{ddl} }
  sub _query_async_pinned {
    my ($self, $conn, $sql) = @_;
    push @{ $self->{captured} }, $sql;
    return $self->future_class->done;
  }
}

my $atomic = 'CREATE FUNCTION f() RETURNS int LANGUAGE sql '
           . 'BEGIN ATOMIC SELECT 1; SELECT 2; END';
my $rule   = 'CREATE RULE r AS ON INSERT TO t DO ALSO '
           . '(INSERT INTO a VALUES (1); INSERT INTO b VALUES (2))';

sub run_deploy {
  my (%o) = @_;
  my $b = Test::SplitBackend->new(%o);
  my $f = $b->deploy_async('schema');
  die "deploy_async did not settle\n" unless $f->is_ready;
  die "deploy_async failed\n" if $f->is_failed;
  # The transactional path brackets its runs; only the DDL is of interest.
  return grep { !/\A(?:BEGIN|COMMIT|ROLLBACK)\z/ } @{ $b->{captured} };
}

for my $txn (1, 0) {
  my $mode = $txn ? 'transactional' : 'non-transactional';

  is_deeply [ run_deploy(txn => $txn, dialect => 'postgresql', ddl => "$atomic;") ],
    [ $atomic ],
    "$mode: BEGIN ATOMIC body is one statement under the postgresql dialect";

  is_deeply [ run_deploy(txn => $txn, ddl => "$atomic;") ],
    [ 'CREATE FUNCTION f() RETURNS int LANGUAGE sql BEGIN ATOMIC SELECT 1',
      'SELECT 2', 'END' ],
    "$mode: without a declared dialect the BEGIN ATOMIC body is still cut";

  is_deeply [ run_deploy(txn => $txn, ddl => "$rule;\nCREATE TABLE z (id int);") ],
    [ $rule, 'CREATE TABLE z (id int)' ],
    "$mode: semicolons inside parentheses do not cut a statement";
}

done_testing;
