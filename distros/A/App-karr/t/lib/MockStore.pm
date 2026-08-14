# ABSTRACT: In-memory BoardStore double for command-level regression tests
package MockStore;
use strict;
use warnings;
use App::karr::Config;

# A lightweight stand-in for App::karr::BoardStore that keeps the board's
# effective config and tasks in memory. It exposes the same ref-first
# interface the command classes call (effective_config, save_config,
# load_tasks, all_status_names, status_requires_claim, is_terminal_status,
# git) so commands can be exercised without Git::Native / libgit2.

sub new {
  my ($class, %args) = @_;
  return bless {
    ec    => $args{ec} || App::karr::Config->default_config,
    tasks => $args{tasks} || [],
    saved => undef,
  }, $class;
}

sub effective_config { $_[0]{ec} }
# The mock stands for a board that is there: the writing commands ask before
# they touch anything (App::karr::Role::BoardDiscovery::require_board).
sub board_exists { 1 }

sub save_config {
  my ($self, $effective) = @_;
  $self->{saved} = $effective;
  $self->{ec}    = $effective;
  return 1;
}

# What the last save_config() call persisted (regression assertions read this).
sub saved_config { $_[0]{saved} }

sub load_tasks { @{ $_[0]{tasks} } }

sub all_status_names {
  my ($self) = @_;
  return map { ref $_ ? $_->{name} : $_ } @{ $self->{ec}{statuses} // [] };
}

# Derived, for the same reason is_terminal_status below is: this used to be a
# third inline copy of Config's walk over `statuses` (ticket #121), so a change
# to what require_claim means would have left the double answering the old rule
# while the real store answered the new one.
sub status_requires_claim {
  my ($self, $name) = @_;
  return App::karr::Config->from_merged( $self->{ec} )->status_requires_claim($name);
}

# Derived from the mock's own config, exactly as App::karr::BoardStore derives
# it from the board's -- a double that hardcoded done/archived would answer
# differently from the real store on any board with custom statuses.
sub is_terminal_status {
  my ($self, $name) = @_;
  return App::karr::Config->from_merged( $self->{ec} )->is_terminal_status($name);
}

# Commands reach for ->store->git via SyncLifecycle; a no-op git double keeps
# sync_before/sync_after from blowing up in tests that don't care about Git.
sub git { $_[0]{git} //= MockGit->new }

package MockGit;
use Carp qw( croak );
sub new { bless {}, shift }

# Every method a command reaches on this double while driven through
# MockStore gets an explicit, considered answer here. Nothing falls back to a
# blanket "true" any more (ticket #109) -- a mock that answers 1 to anything
# it wasn't told about is not standing in for "unimplemented", it is handing
# out a plausible-looking success/ownership/content value that the caller has
# no way to tell apart from a real one. That already cost #92 a crash (see
# list_refs/read_ref below) and #104's is_tracked_under is armed the same way:
# unstubbed, it would tell a caller "yes, the project owns this path" and let
# a test pass while asserting the opposite of the truth.
#
# sync_before/sync_after (App::karr::Role::SyncLifecycle) only ever drive this
# double down the success path -- no test here needs a failing pull/push --
# so `1` is the deliberate answer, not a guess standing in for one.
sub pull { 1 }
sub push { 1 }

# A board double has no refs/karr/log/* of its own -- explicit rather than
# left to AUTOLOAD, whose old blanket `return 1` handed
# App::karr::Cmd::Context's activity section a bogus single "ref" (the
# scalar 1) to read as if it were a log entry.
sub list_refs { () }
sub read_ref { undef }

# App::karr::Cmd::Context's activity section builds its own identity (to
# exclude the invoking agent's entries) via
# App::karr::ActivityLog->identity, which calls this. Every MockStore-driven
# `karr context` run reaches it -- t/07, t/108 and t/123 all exercise it with
# the default section set -- so this was silently answered by AUTOLOAD's
# scalar `1` until now, not merely a theoretical gap.
sub git_user_email { 'mockstore@example.com' }

# Anything else -- is_tracked_under (#104) included -- has no considered
# answer here and must not get one by accident. Fail loudly at the call site
# instead of handing back a plausible-looking `1`, so the next Git method a
# command starts calling forces a real stub instead of a silent pass.
our $AUTOLOAD;
sub AUTOLOAD {
  return if $AUTOLOAD =~ /::DESTROY$/;
  ( my $method = $AUTOLOAD ) =~ s/.*:://;
  croak "MockGit has no stub for $method -- add one";
}

1;
