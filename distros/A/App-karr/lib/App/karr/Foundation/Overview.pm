# ABSTRACT: karr-foundation read-only overview -- multi-board status dashboard

package App::karr::Foundation::Overview;
our $VERSION = '0.601';
use Moo;
use Time::Piece;
use Try::Tiny;



has foundation => (
  is       => 'ro',
  weak_ref => 1,
  required => 1,
);

# ---------------------------------------------------------------------------
# Overview (read-only dashboard)
# ---------------------------------------------------------------------------

sub _print_overview {
  my ( $self, $repos ) = @_;
  for my $repo (@$repos) {
    my $karr   = $self->foundation->_load_karr($repo);
    my %states = $self->foundation->_task_states($repo);

    my %count;
    my ( @in_progress, @blocked );
    for my $id ( sort { $a <=> $b } keys %states ) {
      my $st = $states{$id};
      $count{ $st->{status} // 'unknown' }++;
      push @in_progress, $id if ( $st->{status} // '' ) eq 'in-progress';
      push @blocked,     $id if $st->{blocked};
    }

    # The board's own opt-out (refs/karr/config: foundation.enabled) is the
    # dominant fact about a board, so it leads the flag list — and suppresses
    # the 'agent' flag, because that agent will never run here.
    my $disabled = $self->foundation->_board_disabled($repo);

    my @flags;
    push @flags, 'disabled' if $disabled;
    push @flags, 'agent-running' if $self->foundation->_lock_held($repo);
    if ( $self->foundation->_cooldown_active($repo) ) {
      my $until = $self->foundation->_state_get( $repo, 'cooldown_until' ) // 0;
      # Why, not just how long: a board sitting in cooldown is a board doing
      # nothing, and the only other record of the reason is a COMMON-ERROR
      # line somewhere in .karr.log (#160). last_error belongs to the run that
      # set this deadline — the next run that is not a common error drops it.
      my $why = $self->foundation->_state_get( $repo, 'last_error' );
      push @flags, 'cooldown ' . ( $until - time ) . 's'
                 . ( defined $why ? " ($why)" : '' );
    }
    # Which agent, not just that there is one: a fleet with several agent
    # definitions is the case this exists for, and "agent" alone answers the
    # least interesting question about a board. A named agent that is not
    # currently available says so here too, because from the outside that board
    # and a board in cooldown are doing the same nothing.
    my ( $agent_error, $waiting );
    unless ( $disabled ) {
      my ( $cmd, $agent, $wait );
      try { ( $cmd, $agent, $wait ) = $self->foundation->_resolve_agent( $repo, $karr ) }
      catch { $agent_error = "$_"; chomp $agent_error };
      if ( defined $agent_error ) {
        push @flags, 'agent-error';
      }
      elsif ( defined $wait ) {
        # Routed by the assignment, and told to wait (#210): every agent in
        # this board's fallback chain is failing, or the chain says WAIT. Its
        # own flag rather than no flag at all, because a board waiting for an
        # agent to come back and a board nobody configured an agent for look
        # identical from here and are fixed by different things.
        push @flags, 'agent-waiting';
        $waiting = $wait;
      }
      elsif ( defined $cmd ) {
        my $flag = 'agent';
        if ( $agent ) {
          $flag .= ':' . $agent->{name};
          $flag .= ' failing'
            unless $self->foundation->_agents->available( $agent->{name} );
        }
        push @flags, $flag;
      }
    }

    my $total = keys %states;
    printf "%s\n", $repo->basename;
    printf "  %d tasks", $total;
    print '  [' . join( ', ', @flags ) . ']' if @flags;
    print "\n";
    if (%count) {
      printf "  %s\n", join( '  ', map { "$_:$count{$_}" } sort keys %count );
    }
    printf "  disabled:    %s\n", $disabled->{reason} // 'no reason given'
      if $disabled;
    printf "  agent-error: %s\n", $agent_error if defined $agent_error;
    printf "  waiting:     %s\n", $waiting          if defined $waiting;
    printf "  in-progress: %s\n", join( ', ', map { "#$_" } @in_progress ) if @in_progress;
    printf "  blocked:     %s\n", join( ', ', map { "#$_" } @blocked )     if @blocked;
    print "\n";
  }
  $self->_print_agents;
  $self->_print_questions;
  return;
}

# ---------------------------------------------------------------------------
# Agent availability (local config, per machine)
# ---------------------------------------------------------------------------

sub _print_agents {
  my ( $self ) = @_;
  my $agents = $self->foundation->_agents;
  my @names  = try { $agents->names } catch {
    warn "karr-foundation: $_";
    ();
  };
  return unless @names;

  my $width = 0;
  for my $n ( @names ) { $width = length $n if length $n > $width }

  print "Agents\n";
  for my $name ( @names ) {
    my $def = $agents->definitions->{$name};
    # Which one is the fleet's judgement layer, said here because this is the
    # block that answers "what can run on this machine" -- and a coordination
    # agent that is failing is why no new plan has appeared (#210).
    printf "  %-*s  %s%s\n", $width, $name, _availability_line( $agents, $name ),
      ( ( $def->{role} // '' ) eq 'coordinator' ? '  (coordinator)' : '' );
    next unless $self->foundation->verbose;
    printf "  %-*s  kind: %s\n", $width, '', $def->{kind};
    # The description is prose and is printed as written -- it is the selection
    # criterion a language model reads, not a field, so nothing here reformats
    # or truncates it.
    if ( defined $def->{description} && length $def->{description} ) {
      my $text = $def->{description};
      $text =~ s/\s+\z//;
      printf "  %-*s  %s\n", $width, '', $_ for split /\n/, $text;
    }
  }
  print "\n";
  return;
}

# ---------------------------------------------------------------------------
# The question mailbox (fleet-wide, in the hub)
# ---------------------------------------------------------------------------

# An open question is a chain waiting for somebody, and the somebody is whoever
# reads this. Printed for the same reason the agent block is: a question nobody
# sees is a chain nobody unblocks, and the id printed here is the one argument
# `karr-foundation answer` needs. Settled questions are not shown -- the mailbox
# is what is outstanding, not an archive.
sub _print_questions {
  my ( $self ) = @_;
  my $mailbox = $self->foundation->_questions or return;
  my @open = try { $mailbox->open_questions } catch {
    warn "karr-foundation: $_";
    ();
  };
  return unless @open;

  print "Open questions\n";
  for my $q ( @open ) {
    my $r = $mailbox->resolve($q) || {};
    printf "  #%s  %s\n", $q->{id}, $q->{question};
    my @facts;
    push @facts, 'options: ' . join( ', ', @{ $q->{options} } ) if $q->{options};
    # What happens if this stays unanswered, said in the same line, because
    # that is the difference between a question somebody must answer and one
    # that answers itself in an hour.
    push @facts,
      ( $r->{state} // '' ) eq 'overdue'
        ? 'overdue: ' . $q->{policy}
          . ( defined $r->{answer} ? " ($r->{answer})" : '' )
        : $q->{policy} . ( defined $q->{deadline} ? " after $q->{deadline}" : '' );
    printf "      %s\n", join( '  ', @facts );
  }
  print "\n";
  return;
}

# ok / failing since X / next attempt at Y -- the three states karr keeps, said
# in the order somebody reads them in.
sub _availability_line {
  my ( $agents, $name ) = @_;
  my $av = $agents->availability( $name );
  if ( ( $av->{state} // 'ok' ) eq 'failing' ) {
    my $line = 'failing since ' . _stamp( $av->{failing_since} )
             . ', next attempt at ' . _stamp( $av->{next_attempt} );
    $line .= " ($av->{last_error})" if defined $av->{last_error};
    return $line;
  }
  # An agent that came back carries the last outage with it: that record is
  # what the fixed-interval probe exists to leave behind, and a rhythm nobody
  # ever sees is a rhythm nobody reads.
  my $last = ( $av->{recovered} // [] )->[-1];
  return 'ok' unless $last && defined $last->{seconds};
  return 'ok (last outage ' . _duration( $last->{seconds} )
       . ', back at ' . _stamp( $last->{recovered_at} ) . ')';
}

sub _stamp {
  my ( $epoch ) = @_;
  return '?' unless defined $epoch && $epoch =~ /\A[0-9]+\z/;
  return localtime( $epoch )->strftime('%Y-%m-%dT%H:%M:%S');
}

sub _duration {
  my ( $s ) = @_;
  return "${s}s" if $s < 90;
  return int( $s / 60 ) . 'm' if $s < 5400;
  return sprintf '%.1fh', $s / 3600;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::Foundation::Overview - karr-foundation read-only overview -- multi-board status dashboard

=head1 VERSION

version 0.601

=head1 DESCRIPTION

L<App::karr::Foundation::Overview> renders the read-only cross-board dashboard
shown by C<karr-foundation --status> and whenever no board has an agent
configured: per repo it prints the task-status counts, the in-progress and
blocked task ids, and disabled / lock / cooldown / agent flags. A board that
opted out of automated agent runs (C<karr disable>) is shown with a C<disabled>
flag and a C<disabled:> line carrying its reason; its C<agent> flag is
suppressed, because no agent runs there. A board in cooldown carries the
remaining wait and the error that caused it (C<cooldown 240s (rate limit)>),
since a parked board is a board doing nothing. A weak back-reference to the
owning foundation supplies the board data and state helpers.

Where the local config defines named agents (L<App::karr::Foundation::Agents>)
the boards are followed by one C<Agents> block: per agent C<ok>, or C<failing
since X, next attempt at Y> with the error that caused it. That block is the
whole visible half of availability probing -- an outage nobody can see is an
outage nobody fixes. With C<--verbose> each agent also prints its kind and its
prose description, which is otherwise carried purely for the coordination agent
that routes work.

=head2 foundation

The owning L<App::karr::Foundation> instance, held C<weak_ref> to avoid a
reference cycle. Supplies the per-repo board data, state helpers, agent
registry, and question mailbox this dashboard reads.

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
