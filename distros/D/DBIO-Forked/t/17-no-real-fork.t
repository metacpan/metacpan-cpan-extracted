use strict;
use warnings;
use Test::More;
use POSIX qw(WNOHANG);

use DBIO::Forked::Storage;

# OFFLINE test: a perl without a real fork() is refused at the first query.
#
# WHY: Model A is one process per query. A perl whose fork() is only a
# pseudo-fork emulated with threads ($Config{d_fork} unset, e.g. Strawberry
# Perl) does not carry it: the "child" shares the parent's interpreter, handles
# and pipe. The backend must say so, naming the missing fork, at the call -- not
# misbehave or hang later. The decision is made on the capability, never on the
# name of the operating system. The predicate is _has_real_fork; this file
# replaces it to stand in for such a perl.
#
# WHAT RUNS FOR REAL: DBIO::Forked::Storage and its _run_forked. THE
# SUBSTITUTION: the predicate (here) and the sync storage (a mock, no DBI).

alarm 60;

{
  package t::Mock::Storage;
  sub new { bless {}, shift }
  sub select        { shift; return ([ 1, 'Alice' ]) }
  sub select_single { shift; return (1, 'Alice') }
  sub insert        { shift; return { id => 1 } }
  sub update        { shift; return 1 }
  sub delete        { shift; return 1 }
  sub txn_do        { my ($self, $code, @args) = @_; $code->(@args) }

  package t::Mock::Schema;
  sub new { my ($class, $storage) = @_; bless { storage => $storage }, $class }
  sub storage { $_[0]->{storage} }
}

my $schema  = t::Mock::Schema->new(t::Mock::Storage->new);   # held: the backend keeps it weakly
my $storage = DBIO::Forked::Storage->new($schema);

# Nothing started: no child to wait for, and no pipe opened for it (the open
# descriptors do not change).
my $can_count_fds = -d '/proc/self/fd';
sub open_fds { scalar grep { -e "/proc/self/fd/$_" } 0 .. 255 }

{
  no warnings 'redefine';
  local *DBIO::Forked::Storage::_has_real_fork = sub { 0 };

  my $fds = $can_count_fds ? open_fds() : 0;

  my %calls = (
    select_async        => [ 'artist' ],
    select_single_async => [ 'artist' ],
    insert_async        => [ 'artist', { name => 'x' } ],
    update_async        => [ 'artist', { name => 'y' }, { id => 1 } ],
    delete_async        => [ 'artist', { id => 1 } ],
    txn_do_async        => [ sub { 1 } ],
  );
  for my $method (sort keys %calls) {
    my $future = eval { $storage->$method(@{ $calls{$method} }) };
    like $@, qr/no real fork\(\).*\$Config\{d_fork\}/s,
      "$method: croaks, naming the missing fork";
    ok !defined $future, "$method: ... and returns no Future";
  }

  is waitpid(-1, WNOHANG), -1, 'no child was started';
  is open_fds(), $fds, 'no pipe was left open' if $can_count_fds;
}

# The predicate true: everything as before.
{
  no warnings 'redefine';
  local *DBIO::Forked::Storage::_has_real_fork = sub { 1 };
  my @rows = $storage->select_async('artist')->get;
  is_deeply \@rows, [ [ 1, 'Alice' ] ], 'with a real fork the query runs as before';
  is waitpid(-1, WNOHANG), -1, '... and its child was reaped';
}

# Unreplaced, on the perl running this file: the predicate tells the truth.
{
  require Config;
  is !!$storage->_has_real_fork, !!$Config::Config{d_fork},
    '_has_real_fork reads $Config{d_fork}';
}

done_testing;
