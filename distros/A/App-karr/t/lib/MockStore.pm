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

sub status_requires_claim {
  my ($self, $name) = @_;
  my ($sc) = grep { (ref $_ ? $_->{name} : $_) eq $name } @{ $self->{ec}{statuses} // [] };
  return 0 unless $sc && ref $sc;
  return $sc->{require_claim} ? 1 : 0;
}

sub is_terminal_status {
  my ($self, $name) = @_;
  return ($name eq 'done' || $name eq 'archived') ? 1 : 0;
}

# Commands reach for ->store->git via SyncLifecycle; a no-op git double keeps
# sync_before/sync_after from blowing up in tests that don't care about Git.
sub git { $_[0]{git} //= MockGit->new }

package MockGit;
sub new { bless {}, shift }
sub pull { 1 }
sub push { 1 }
sub fetch { 1 }
sub has_remote { 0 }
sub AUTOLOAD {
  our $AUTOLOAD;
  return if $AUTOLOAD =~ /::DESTROY$/;
  return 1;
}

1;
