# ABSTRACT: Report and resolve cross-board dependencies

package App::karr::Cmd::Needs;
our $VERSION = '0.601';
use Moo;
use MooX::Cmd;
use MooX::Options (
  usage_string => 'USAGE: karr needs [ID[,ID,...]] [--resolve] [--board NAME=PATH] [--fleet-config FILE] [--json]',
);
use App::karr::Role::BoardAccess;
use App::karr::Role::Output;
use App::karr::Role::TaskMutation;
use App::karr::CrossBoard;
use App::karr::Error qw( command_hint );

with 'App::karr::Role::BoardAccess', 'App::karr::Role::Output',
     'App::karr::Role::TaskMutation';


option resolve => (
  is  => 'ro',
  doc => 'Drop settled links and unblock a card whose last link settled',
);

option board => (
  is     => 'ro',
  format => 's@',
  doc    => 'Locate a board: NAME=PATH (repeatable)',
);

# Not --config: App::karr::Role::BoardDiscovery already owns a `config`
# accessor (this board's own App::karr::Config), and the name says the more
# useful thing anyway -- this is the fleet's local config, not the board's.
option fleet_config => (
  is     => 'ro',
  format => 's',
  doc    => 'Fleet config file (default: ~/.config/karr-foundation/config.yml)',
);

# --board NAME=PATH, refused as a usage error before anything is read: it is a
# plain option value, so a typo in it is wrong for the whole invocation
# (ticket #54's rule).
sub _overrides {
  my ($self) = @_;
  my %map;
  for my $entry ( @{ $self->board // [] } ) {
    my ( $name, $path ) = $entry =~ /\A([^=]+)=(.+)\z/;
    # The board name is salvaged out of what was typed wherever there is one --
    # `--board other-repo` and `--board other-repo=` both name a board and only
    # miss the path, so the line that would have worked can keep the name and
    # leave PATH as the one placeholder (ticket k263).
    unless ( defined $name && length $path ) {
      my ($typed) = $entry =~ /\A([^=]+)/;
      $self->usage_error(
        qq{invalid --board "$entry" (expected NAME=PATH):\n}
          . command_hint( 'needs', '--board',
              ( defined $typed && length $typed ? $typed : 'NAME' ) . '=PATH' ) );
    }
    $map{$name} = $path;
  }
  return \%map;
}

# This board's own name, which is what the far card has to name back for a link
# to count as verified. The repository's directory basename: the same name
# `karr-foundation --status` prints and the same name the escalation convention
# writes into `escalated-from:<repo>#<id>`.
sub _own_board_name {
  my ($self) = @_;
  return $self->git_root->basename;
}

sub _cards {
  my ( $self, $args_ref ) = @_;

  my @pos = $self->positional_args($args_ref);
  if ( defined $pos[0] && length $pos[0] ) {
    my @tasks;
    for my $id ( $self->parse_ids( $pos[0] ) ) {
      # The id names no card, so nothing about this card can be asked -- what
      # would have worked is the command that shows which ids exist (k263).
      my $task = $self->find_task($id)
        or die "Task $id not found on this board:\n"
          . command_hint( 'list', '--compact' ) . "\n";
      push @tasks, $task;
    }
    return @tasks;
  }

  return sort { $a->id <=> $b->id }
    grep { scalar App::karr::CrossBoard->needs_of($_) } $self->load_tasks;
}

sub execute {
  my ( $self, $args_ref, $chain_ref ) = @_;

  $self->check_positional_args( $args_ref, 1 );
  my $overrides = $self->_overrides;

  # A report pays for no transport, the way `list` and `show` pay for none;
  # only the writing half syncs. #190 split the fleet namespace the same way
  # and for the same reason.
  if ( $self->resolve ) {
    $self->sync_before;
    $self->require_board;
  }
  else {
    $self->require_local_board;
  }

  my $fleet = App::karr::CrossBoard->new(
    overrides => $overrides,
    ( defined $self->fleet_config ? ( config_file => $self->fleet_config ) : () ),
  );
  my $me = $self->_own_board_name;

  my @report;
  for my $task ( $self->_cards($args_ref) ) {
    my @refs = App::karr::CrossBoard->needs_of($task);
    next unless @refs;

    my @links = map {
      $fleet->link_state( $_, origin => { board => $me, id => $task->id } )
    } @refs;

    push @report, {
      id      => $task->id,
      title   => $task->title,
      blocked => ( $task->has_blocked ? 1 : 0 ),
      needs   => \@links,
    };
  }

  $self->_resolve_cards( \@report ) if $self->resolve;

  $self->sync_after if $self->resolve;

  return $self->print_json( \@report ) if $self->json;
  $self->_print_report( \@report );
}

# One guarded write per card, and only for cards with something to settle. The
# link states were read before the guard, so they are a hint that ages exactly
# as every other karr client's view does -- what the callback re-decides
# against the fresh card is which of those links the card still carries and
# whether anything is left after they go.
sub _resolve_cards {
  my ( $self, $report ) = @_;

  for my $entry (@$report) {
    my @settled = grep { $_->{state} eq 'settled' } @{ $entry->{needs} };
    next unless @settled;

    my @refs = map { App::karr::CrossBoard->parse_ref( 'needs', $_->{ref} ) } @settled;
    my $unblocked;

    my $task = $self->update_task_guarded( $entry->{id}, sub {
      my ($task) = @_;
      undef $unblocked;
      App::karr::CrossBoard->remove_needs( $task, \@refs );

      # The card is unblocked only when it waits on nothing else at all. A
      # link is what says "this card is waiting on another board", so the last
      # one going is what the escalating agent's `--block` was for; while one
      # is left the block still has something to point at.
      return if App::karr::CrossBoard->needs_of($task);
      return unless $task->has_blocked;
      $unblocked = $task->has_block_reason ? $task->block_reason : 'no reason given';
      $task->unblock;
    } );

    $entry->{resolved}  = [ map { $_->{ref} } @settled ];
    $entry->{unblocked} = defined $unblocked ? 1 : 0;
    $entry->{was_blocked_because} = $unblocked if defined $unblocked;
    $entry->{blocked} = $task->has_blocked ? 1 : 0;
    $_->{state} = 'resolved' for @settled;
  }
  return;
}

sub _print_report {
  my ( $self, $report ) = @_;

  unless (@$report) {
    print "No cross-board dependencies.\n";
    return;
  }

  for my $entry (@$report) {
    printf "Task #%d: %s\n", $entry->{id}, $entry->{title};
    for my $link ( @{ $entry->{needs} } ) {
      printf "  %s %s -- %s%s\n",
        ( $link->{state} eq 'resolved' ? 'resolved' : 'needs' ),
        $link->{ref}, $link->{detail}, $self->_verification_note($link);
    }
    printf "  unblocked (was: %s)\n", $entry->{was_blocked_because}
      if defined $entry->{was_blocked_because};
  }
  return;
}

# The half of the escalation protocol nothing checked before: whether the far
# card names this one back. A back-reference to a different card is shown
# rather than swallowed -- two cards that disagree about which escalation they
# are is precisely the mistake worth seeing.
sub _verification_note {
  my ( $self, $link ) = @_;
  return '' unless exists $link->{status};
  return ', back-reference verified' if $link->{verified};
  return sprintf ', back-reference names %s', join( ', ', @{ $link->{back_refs} } )
    if $link->{back_refs};
  return ', no back-reference';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::Cmd::Needs - Report and resolve cross-board dependencies

=head1 VERSION

version 0.601

=head1 SYNOPSIS

    karr needs                                   # what is this board waiting on?
    karr needs --board other-repo=/srv/other     # ... and where that board is
    karr needs --resolve                         # settle what has been finished
    karr needs 5 --json

=head1 DESCRIPTION

The reading and resolving end of cross-board dependencies (ticket #192). A card
that cannot be worked on until something is fixed in another repository records
that as C<< needs:<board>#<id> >> (C<< karr create --needs >>, C<< karr edit
--add-needs >>); the card raised in the other repository records the other half
as C<< escalated-from:<board>#<id> >>. This command is what reads both ends
back.

Without C<--resolve> it reports and changes nothing: every card carrying a
link, what the far card's status is where the far board can be read, and
whether that far card names this one back. With C<--resolve> it drops every
link whose far card has reached one of the B<far> board's own terminal
statuses, and when that was a card's last outstanding link it lifts the
C<blocked> flag as well, printing the reason it lifted so nothing is cleared
silently.

Board names, not paths. See L<App::karr::CrossBoard/What the card carries, and
what it does not>: the card carries the other board's name, this machine
supplies the directory -- from C<--board NAME=PATH>, or from the fleet config
the rest of karr-foundation already reads. A name this machine cannot place is
reported and the command still exits C<0>: a machine holding four repositories
of a six-repository fleet has an honest report to give about the four, and
failing on the first unplaceable name would give none.

=head2 What it does not do

It does not fetch. The far board is read as it stands in that working copy, so
the answer is as fresh as that repository's last C<karr sync>.

It does not block anything, and neither does the link it reports. C<depends_on>
warns and hands the card over (ticket #123), L<App::karr::Foundation::Picker>
does not filter on it (ticket #185), and a cross-board link follows both. The
flag that actually keeps the waiting card out of C<karr pick> is C<blocked>,
set deliberately by the escalating agent -- the link is the fact, C<blocked> is
the decision -- and lifting it once the last link settles is the whole point of
C<--resolve>.

=head1 SEE ALSO

L<karr>, L<App::karr>, L<App::karr::CrossBoard>, L<App::karr::Cmd::Create>,
L<App::karr::Cmd::Edit>, L<App::karr::Cmd::Show>, L<App::karr::Foundation>

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/karr/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
