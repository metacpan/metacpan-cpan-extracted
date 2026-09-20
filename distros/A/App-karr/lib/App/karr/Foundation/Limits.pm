# ABSTRACT: karr-foundation concurrency limits -- machine ceiling, per-agent estimates, chain header

package App::karr::Foundation::Limits;
our $VERSION = '0.601';
use Moo;
use Try::Tiny;
use App::karr::Error qw( user_error clean_error );



has foundation => (
  is       => 'ro',
  weak_ref => 1,
  required => 1,
);


has chain_limits => (
  is      => 'lazy',
  builder => '_build_chain_limits',
);

sub _build_chain_limits {
  my ( $self ) = @_;
  my $store = $self->foundation->_chain_store or return {};
  my $limits = try {
    $self->foundation->_chain_store->header->{limits};
  } catch {
    warn "karr-foundation: cannot read the chain header: " . clean_error($_) . "\n";
    undef;
  };
  return ref $limits eq 'HASH' ? $limits : {};
}


has concurrent => (
  is      => 'lazy',
  builder => '_build_concurrent',
);

sub _build_concurrent {
  my ( $self ) = @_;
  my $machine = _count( "Config 'concurrent'",
    $self->foundation->_config_data->{concurrent} ) // 1;
  my $chain = $self->_soft_count( "The chain header's 'concurrent'",
    $self->chain_limits->{concurrent} );
  return defined $chain && $chain < $machine ? $chain : $machine;
}


has per_agent => (
  is      => 'lazy',
  builder => '_build_per_agent',
);

sub _build_per_agent {
  my ( $self ) = @_;
  my $agents = $self->foundation->_agents;
  my $defs   = $agents->definitions;

  my %limit;
  for my $name ( sort keys %$defs ) {
    my $n = _count( "Agent '$name' concurrent", $defs->{$name}{concurrent} );
    $limit{$name} = $n if defined $n;
  }

  my $chain = $self->chain_limits->{per_agent};
  if ( defined $chain && ref $chain ne 'HASH' ) {
    warn "karr-foundation: the chain header's 'per_agent' is not a mapping "
       . "of agent name => count -- ignored\n";
    $chain = undef;
  }
  for my $name ( sort keys %{ $chain // {} } ) {
    # The names here are agent definitions, so this machine's definitions are
    # what they are checked against. Unknown is not an error (see DESCRIPTION):
    # the chain is shared, the agent list is not.
    unless ( $defs->{$name} ) {
      $self->foundation->_say_verbose(
        "chain limit for agent '$name' ignored -- not defined on this machine" );
      next;
    }
    my $n = $self->_soft_count( "The chain header's limit for agent '$name'",
      $chain->{$name} ) // next;
    $limit{$name} = $n if !defined $limit{$name} || $n < $limit{$name};
  }
  return \%limit;
}

# A count as a config writes one: a positive whole number. undef passes through
# as "not set"; anything else is refused rather than rounded, because a
# concurrent: 2.5 that silently became 2 -- or a concurrent: 0 that silently
# became "never run anything" -- is a configuration that lies to its operator.
sub _count {
  my ( $what, $value ) = @_;
  return undef unless defined $value;
  user_error("$what must be a positive whole number, not a structure")
    if ref $value;
  my $v = "$value";
  $v =~ s/\A\s+//;
  $v =~ s/\s+\z//;
  user_error("$what must be a positive whole number, not '$value'")
    unless $v =~ /\A[0-9]+\z/ && $v + 0 > 0;
  return $v + 0;
}

# The same for a value that came out of the chain header rather than out of
# this machine's config. It warns and yields undef instead of dying: the header
# was written elsewhere, and one bad number in it must not stop this machine
# from running at its own ceiling.
sub _soft_count {
  my ( $self, $what, $value ) = @_;
  return undef unless defined $value;
  return try {
    _count( $what, $value );
  } catch {
    warn "karr-foundation: " . clean_error($_) . " -- ignored\n";
    undef;
  };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::Foundation::Limits - karr-foundation concurrency limits -- machine ceiling, per-agent estimates, chain header

=head1 VERSION

version 0.601

=head1 DESCRIPTION

How many agents F<karr-foundation> may have running at once, and how many of
any one named agent. Three levels, B<tightest wins>:

=over 4

=item 1. C<concurrent:> in the local config -- the machine ceiling.

It protects this machine's CPU and memory and is B<not> a quota: it says
nothing about what any account may spend, only about what this box can carry.
It is the only one of the three that is always present, because it defaults to
C<1> -- which is exactly the serial runner F<karr-foundation> has always been.
Concurrency is opt-in for the same reason agent execution is: a default that
suddenly started four agents on an operator's laptop would be a surprise, and
the surprise would arrive on a machine, not in a review.

=item 2. C<concurrent:> on a named agent definition -- the operator's estimate.

This is where the prose policy lands as a number: roughly how many sessions of
this agent may run side by side. It is a B<guess about somebody else's rate
limit> and is allowed to be wrong, because being wrong is cheap here -- the
agent starts failing, L<App::karr::Foundation::Agents> marks it so, every board
on it is skipped for one probe interval, and the fallback takes over. That is
the whole error budget this number needs.

=item 3. C<limits:> in the chain header -- what one particular run declares.

    limits:
      concurrent: 4
      per_agent:
        minimax: 2

The chain is shared state, so this travels with the plan rather than with the
machine. It can only ever tighten: a chain asking for eight concurrent runs on
a box configured for two gets two.

=back

The C<per_agent> names are B<agent definition names> -- the keys of the
config's C<agents:> section (L<App::karr::Foundation::Agents/definitions>), not
a second, free-form namespace. A name this machine does not define is dropped
with a verbose note rather than an error: agent definitions are local and only
local by design, so a chain written on a machine with C<minimax> reaching one
without it is the expected case, not a broken plan.

A malformed number is treated by where it came from. In the local config it is
a C<user_error>: it is the operator's own file, and a C<concurrent: "two">
silently meaning one is the kind of quiet wrong answer this distribution
refuses. In the chain header it warns and is ignored: the header was written on
another machine, and refusing to run the fleet over a foreign typo is worse
than running it at the local ceiling.

=head1 SEE ALSO

L<App::karr::Foundation>, L<App::karr::Foundation::Agents>,
L<App::karr::Foundation::ChainStore>

=head2 foundation

The owning L<App::karr::Foundation>, held weakly. Required.

=head2 chain_limits

The C<limits:> mapping of the current chain header, or C<{}> when there is no
hub configured, no chain written, or nothing readable in it. Read once per
foundation run -- the fleet namespace is pulled before this is built (see
L<App::karr::Foundation/_sync_pull_foundation>), so it is the fleet's answer
rather than whatever this machine happened to have.

=head2 concurrent

The effective machine-wide ceiling: how many boards may have an agent on them
at once. Always at least C<1>, so a foundation configured with nothing at all
behaves exactly as the serial runner did.

=head2 per_agent

Agent name => how many runs of that agent may be live at once, for the agents
that have a limit at all. An agent that appears nowhere here is bounded only by
L</concurrent>.

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
