use strict;
use warnings;
use Test::More;

use DBIO::Firebird::Storage;
use DBIO::Firebird::Storage::InterBase;
use DBIO::Firebird::Storage::ODBC;

# OFFLINE (karr k49).
#
# WHY: after the server refuses a DDL commit (`object TABLE "..." is in use`)
# DBD::Firebird leaves the transaction as it is and every later statement on
# the handle fails -- the ping's select too. core's dbh_do replaces the
# connection and runs its block again when the ping fails, so the refused DDL
# was reported as success on a new connection. _ping must tell "the connection
# is gone" from "the last commit was refused".
#
# What this file claims about Storage::InterBase::_ping (inherited by
# DBIO::Firebird::Storage):
#   1. a handle that answers is alive and nothing is rolled back;
#   2. a handle that fails the select but answers after begin_work + rollback
#      is alive -- with AutoCommit on, and the rollback is taken that way, as a
#      plain rollback does nothing under AutoCommit;
#   3. a handle that keeps failing is dead, and the ping asks twice, no more;
#   4. a handle that cannot even begin_work is dead;
#   5. with AutoCommit off (a transaction of the application is on the handle)
#      nothing is rolled back and a failed select is a dead handle;
#   6. no handle is no connection;
#   7. the ODBC storage does not do this (ADR 0010).
#
# THE SUBSTITUTION: a stand-in database handle that fails `do` while "poisoned"
# and clears the state on a begin_work + rollback pair, as measured against
# Firebird 5.0.4 / DBD::Firebird 1.39 in t/32-failed-ddl-no-reconnect-live.t.

our @LOG;

{
  package T::Dbh;
  sub new { my ($c, %a) = @_; return bless { AutoCommit => 1, poisoned => 0, dead => 0, %a }, $c }
  sub do {
    my $self = shift;
    push @main::LOG, 'do';
    die "poisoned\n" if $self->{poisoned} or $self->{dead};
    return 1;
  }
  sub begin_work {
    my $self = shift;
    push @main::LOG, 'begin_work';
    die "dead\n" if $self->{dead};
    $self->{AutoCommit} = 0;
  }
  sub rollback {
    my $self = shift;
    push @main::LOG, 'rollback';
    $self->{poisoned} = 0 unless $self->{AutoCommit};
    $self->{AutoCommit} = 1;
  }
}

{
  package T::Storage;
  our @ISA = ('DBIO::Firebird::Storage::InterBase');
  sub _dbh { $_[0]{dbh} }
}

sub ping_of {
  my ($class, $dbh) = @_;
  @LOG = ();
  return bless({ dbh => $dbh }, 'T::Storage')->_ping;
}

my $class = 'DBIO::Firebird::Storage::InterBase';

is(ping_of($class, T::Dbh->new), 1, '1. a handle that answers is alive');
is_deeply(\@LOG, ['do'], '... and nothing was rolled back');

my $poisoned = T::Dbh->new(poisoned => 1);
is(ping_of($class, $poisoned), 1, '2. a handle left failing by a refused commit is alive');
is_deeply(\@LOG, [qw( do begin_work rollback do )],
  '... after begin_work + rollback, then asked again');
is($poisoned->{AutoCommit}, 1, '... and AutoCommit is on again');

is(ping_of($class, T::Dbh->new(dead => 1)), 0, '4. a handle that cannot begin_work is dead');
is_deeply(\@LOG, [qw( do begin_work )], '... after one select and the begin_work that failed');

my $stuck = T::Dbh->new(poisoned => 1);
{
  no warnings 'redefine';
  local *T::Dbh::rollback = sub { push @main::LOG, 'rollback'; $_[0]{AutoCommit} = 1 };
  is(ping_of($class, $stuck), 0, '3. a handle that keeps failing after the rollback is dead');
  is_deeply(\@LOG, [qw( do begin_work rollback do )], '... the ping asked twice and no more');
}

my $in_txn = T::Dbh->new(poisoned => 1, AutoCommit => 0);
is(ping_of($class, $in_txn), 0, '5. with AutoCommit off a failed select is a dead handle');
is_deeply(\@LOG, ['do'], '... and the application\'s transaction was not rolled back');

is(ping_of($class, undef), 0, '6. no handle, no connection');

isnt(DBIO::Firebird::Storage::ODBC->can('_ping'), $class->can('_ping'),
  '7. the ODBC storage does not use this _ping');
is(DBIO::Firebird::Storage->can('_ping'), $class->can('_ping'),
  'DBIO::Firebird::Storage does');

done_testing;
