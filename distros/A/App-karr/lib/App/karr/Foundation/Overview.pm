# ABSTRACT: karr-foundation read-only overview — multi-board status dashboard

package App::karr::Foundation::Overview;
our $VERSION = '0.400';
use Moo;


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

    my @flags;
    push @flags, 'agent-running' if $self->foundation->_lock_held($repo);
    if ( $self->foundation->_cooldown_active($repo) ) {
      my $until = $self->foundation->_state_get( $repo, 'cooldown_until' ) // 0;
      push @flags, 'cooldown ' . ( $until - time ) . 's';
    }
    push @flags, 'agent' if defined $self->foundation->_agent_command( $repo, $karr );

    my $total = keys %states;
    printf "%s\n", $repo->basename;
    printf "  %d tasks", $total;
    print '  [' . join( ', ', @flags ) . ']' if @flags;
    print "\n";
    if (%count) {
      printf "  %s\n", join( '  ', map { "$_:$count{$_}" } sort keys %count );
    }
    printf "  in-progress: %s\n", join( ', ', map { "#$_" } @in_progress ) if @in_progress;
    printf "  blocked:     %s\n", join( ', ', map { "#$_" } @blocked )     if @blocked;
    print "\n";
  }
  return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::Foundation::Overview - karr-foundation read-only overview — multi-board status dashboard

=head1 VERSION

version 0.400

=head1 DESCRIPTION

L<App::karr::Foundation::Overview> renders the read-only cross-board dashboard
shown by C<karr-foundation --status> and whenever no board has an agent
configured: per repo it prints the task-status counts, the in-progress and
blocked task ids, and lock / cooldown / agent flags. A weak back-reference to
the owning foundation supplies the board data and state helpers.

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

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
