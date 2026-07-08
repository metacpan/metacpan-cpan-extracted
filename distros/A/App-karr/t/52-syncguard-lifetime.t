use strict;
use warnings;
use Test::More;

use App::karr::Role::SyncLifecycle;

# Regression for ticket #28:
#   Every command calls $self->sync_before; in VOID context. sync_before built
#   a SyncGuard and returned it, but nobody kept the returned guard alive, so it
#   was DESTROYed the instant sync_before returned -- firing a redundant push
#   BEFORE the command body ran (the doubled "Push attempt 1 of 3..." seen on
#   every karr move/handoff). The documented "insurance on die before
#   sync_after" therefore never engaged: by the time the body died, the guard
#   was long gone.
#
#   The fix keeps the guard alive for the duration of the command by stashing it
#   on the SyncLifecycle role; sync_after neutralises it after a successful push.

# A counting Git double: records the exact order of pull/push calls so we can
# assert *when* the guard fires relative to the command body.
{
  package CountingGit;
  sub new    { bless { log => [], pushes => 0, pulls => 0 }, shift }
  sub pull   { my ($self) = @_; $self->{pulls}++;  CORE::push @{ $self->{log} }, 'pull'; 1 }
  sub push   { my ($self) = @_; $self->{pushes}++; CORE::push @{ $self->{log} }, 'push'; 1 }
  sub mark   { my ($self, $what) = @_; CORE::push @{ $self->{log} }, $what }
  sub last_error { undef }
  sub pushes { $_[0]{pushes} }
  sub events { @{ $_[0]{log} } }
}

# Minimal stand-in for a command: composes the sync lifecycle role and calls
# sync_before / sync_after in VOID context, exactly as every real Cmd/* does.
{
  package LifecycleBoard;
  use Moo;
  use MooX::Options;    # SyncLifecycle now carries a MooX::Options option (--quiet)
  with 'App::karr::Role::SyncLifecycle';
  has git => ( is => 'ro', required => 1 );
}

# Silence the "Pull attempt.../Push attempt..." retry chatter these calls emit
# on STDERR; this test asserts on push *counts and ordering*, not on messages.
sub silent (&) {
  my ($code) = @_;
  local *STDERR;
  open STDERR, '>', \(my $buf) or die "cannot redirect STDERR: $!";
  $code->();
}

subtest 'sync_before performs no push in void context (guard is held)' => sub {
  my $git = CountingGit->new;

  silent {
    my $board = LifecycleBoard->new( git => $git );
    $board->sync_before;    # void context -- just like every command

    is $git->pushes, 0,
      'sync_before does not push (guard survives, not discarded in void context)';

    $board->sync_after;     # neutralise + clean teardown
  };
};

subtest 'full lifecycle: pull -> body -> push, exactly one push' => sub {
  my $git = CountingGit->new;

  silent {
    my $board = LifecycleBoard->new( git => $git );
    $board->sync_before;
    $git->mark('body');     # the command body does its work here
    $board->sync_after;

    undef $board;           # a clean sync_after leaves the guard neutralised
  };

  is_deeply [ $git->events ], [ 'pull', 'body', 'push' ],
    'sequence is pull -> body -> push (guard never fires a premature push)';
  is $git->pushes, 1,
    'exactly one push across the whole lifecycle, and none at destruction';
};

subtest 'insurance still engages when the body dies before sync_after' => sub {
  my $git = CountingGit->new;

  silent {
    eval {
      my $board = LifecycleBoard->new( git => $git );
      $board->sync_before;
      die "body blew up\n";   # never reaches sync_after; $board freed on unwind
    };
    is $@, "body blew up\n", 'the body exception propagates unchanged';
  };

  is $git->pushes, 1,
    'guard DESTROY fires the push insurance exactly once when sync_after never ran';
};

done_testing;
