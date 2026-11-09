use strict;
use warnings;

use Test::More;

use DBIO::Sybase::Storage::FreeTDS;

# OFFLINE (karr k65). DBD::Sybase runs a statement on a database handle that
# has an active statement handle over a second connection. BEGIN TRAN, COMMIT
# and ROLLBACK are sent with $dbh->do, so with a cursor open they would miss
# the session of the transaction. The FreeTDS trait therefore
#
#   * on ROLLBACK (also the guard's and txn_do's) finishes every active
#     statement handle of the connection and rolls back on the same dbh;
#   * on BEGIN throws, naming the open cursor, before anything is sent and
#     without moving transaction_depth; on COMMIT it throws the same way, and
#     the core then ends the transaction (karr k372, k99): the cursor is
#     finished and ROLLBACK goes out on the same dbh, depth 0;
#   * does none of it without an active statement handle.
#
# The dbh here is a mock that keeps a log of what is sent and finished, and
# answers ActiveKids / ChildHandles as a DBI handle does. t/64 asks a server.

{
  package T::Kid;
  sub new { bless { Active => 1, log => $_[1], name => $_[2] }, $_[0] }
  sub finish { my $s = shift; push @{ $s->{log} }, "finish $s->{name}"; $s->{Active} = 0; 1 }
}

{
  package T::Dbh;
  sub new { bless { log => [], ActiveKids => 0, ChildHandles => [] }, shift }
  sub add_kid {
    my ($s, $name, $active) = @_;
    my $k = T::Kid->new($s->{log}, $name);
    $k->{Active} = $active ? 1 : 0;
    push @{ $s->{ChildHandles} }, $k;
    $s->{ActiveKids}++ if $active;
    return $k;
  }
  sub FETCH { $_[1] eq 'AutoCommit' ? 1 : $_[0]{ $_[1] } }
  sub do { push @{ $_[0]{log} }, "do $_[1]"; 1 }
}

{
  package T::Storage;
  use base 'DBIO::Sybase::Storage::FreeTDS';
  sub _get_dbh { $_[0]{_dbh} }
  sub _seems_connected { 1 }
  sub ensure_connected { 1 }
  sub dbh_do { my $s = shift; my $c = shift; $s->$c($s->{_dbh}, @_) }
}

sub fresh {
  my $dbh = T::Dbh->new;
  my $s   = T::Storage->new(undef);
  $s->{_dbh} = $dbh;
  $s->{_dbh_autocommit} = 1;
  return ($s, $dbh);
}

# ------------------------------------------------- no active statement handle
{
  my ($s, $dbh) = fresh();
  $dbh->add_kid(done => 0);
  $s->txn_begin;
  $s->txn_commit;
  $s->txn_begin;
  $s->txn_rollback;
  is_deeply $dbh->{log},
    [ 'do BEGIN TRAN', 'do COMMIT', 'do BEGIN TRAN', 'do ROLLBACK' ],
    'no active statement handle: BEGIN TRAN, COMMIT, ROLLBACK as before, nothing finished';
  is $s->transaction_depth, 0, '... and the storage is at depth 0';
}

# ------------------------------------------------------- rollback, open cursor
{
  my ($s, $dbh) = fresh();
  $s->txn_begin;
  my $a = $dbh->add_kid(a => 1);
  my $b = $dbh->add_kid(b => 1);
  $dbh->add_kid(c => 0);
  @{ $dbh->{log} } = ();

  $s->txn_rollback;

  is_deeply $dbh->{log}, [ 'finish a', 'finish b', 'do ROLLBACK' ],
    'rollback with open cursors: every active handle is finished, then ROLLBACK on the same dbh';
  is $s->transaction_depth, 0, '... depth 0 after it';
  ok !$a->{Active} && !$b->{Active}, '... the cursors are ended';
}

# ------------------------------------------------------- begin, open cursor
{
  my ($s, $dbh) = fresh();
  $dbh->add_kid(cur => 1);

  eval { $s->txn_begin };
  like $@, qr/BEGIN TRAN.*open cursor/s, 'begin with an open cursor throws, naming the cursor';
  is_deeply $dbh->{log}, [], '... and sent nothing';
  is $s->transaction_depth, 0, '... transaction_depth did not move';
}

# ------------------------------------------------------ commit, open cursor
{
  my ($s, $dbh) = fresh();
  $s->txn_begin;
  my $k = $dbh->add_kid(cur => 1);
  @{ $dbh->{log} } = ();

  eval { $s->txn_commit };
  like $@, qr/COMMIT.*open cursor/s,
    'commit with an open cursor throws, naming the cursor (before anything is sent)';
  is_deeply $dbh->{log}, [ 'finish cur', 'do ROLLBACK' ],
    '... then the failed commit ends the transaction (core, karr k372): the cursor is finished, ROLLBACK on the same dbh';
  ok !$k->{Active}, '... the cursor is ended';
  is $s->transaction_depth, 0, '... depth 0, no txn_rollback needed';
}

done_testing;
