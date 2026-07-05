package Chorus::Expert;

use 5.006;
use strict;
use warnings;

our $VERSION = '2.01';

=encoding UTF-8

=head1 NAME

Chorus::Expert - Orchestrator for one or more Chorus::Engine agents working on a shared task.

=head1 VERSION

2.01

=head1 DESCRIPTION

C<Chorus::Expert> does three things:

=over 4

=item 1.

Registers one or more L<Chorus::Engine> agents.

=item 2.

Provides every agent with a shared L<Chorus::Frame> called B<BOARD>, used for
inter-agent communication and to carry the input to the pipeline.

=item 3.

Runs a C<do/until> loop over the agents until one of them signals C<SOLVED> or
C<FAILED>.

=back

=head1 SYNOPSIS

  use Chorus::Expert;
  use Chorus::Engine;

  my $agent1 = Chorus::Engine->new(_IDENT => 'Enrich');
  $agent1->addrule( ... );

  my $agent2 = Chorus::Engine->new(_IDENT => 'Validate');
  $agent2->addrule( ... );

  my $xprt = Chorus::Expert->new();
  $xprt->register($agent1, $agent2);

  my $ok = $xprt->process($input);   # 1 = solved, undef = failed

=head1 METHODS

=head2 new

Creates a new C<Chorus::Expert> instance with an empty agent list and a fresh
shared BOARD frame.

  my $xprt = Chorus::Expert->new();

B<Note> -- arguments passed to C<new()> are currently ignored.  To override
C<_MAX_ITER>, assign directly after construction:

  my $xprt = Chorus::Expert->new();
  $xprt->{_MAX_ITER} = 50_000;   # default is 10,000

=head2 register

Registers one or more agents.  Each agent receives:

=over 4

=item * C<BOARD> -- the shared frame, accessible as C<< $agent->BOARD >>.

=item * C<EXPERT> -- a back-reference to this expert instance.

=back

  $xprt->register($agent1, $agent2, $agent3);

Agents are stored in registration order, which determines the order in which
C<process()> calls their C<loop()> method.

The termination agent (the one that calls C<solved()>) should be registered
B<last>.

=head2 debug

Enables verbose output to STDERR for the main process loop.

  $xprt->debug(1);   # enable
  $xprt->debug(0);   # disable

=head2 process

Runs the pipeline.

  my $ok = $xprt->process();           # no input
  my $ok = $xprt->process($something); # $something available as $agent->BOARD->INPUT

The main loop iterates over all registered agents in order, calling C<loop()>
on each one, until C<BOARD->{SOLVED}> or C<BOARD->{FAILED}> is set.  It respects
C<_REPLAY> and C<_REPLAY_ALL> signals from the agents.

An agent tagged with C<_LOCK_UNTIL_STABLE> is skipped when any earlier agent in
the current iteration has already succeeded (C<_SUCCES> is true).  This allows
priority-based sequencing without explicit coupling.

If C<_MAX_ITER> full iterations complete without termination, a warning is emitted
and C<process()> returns C<undef>.

Returns C<1> if C<SOLVED>, C<undef> if C<FAILED> or if C<_MAX_ITER> is exceeded.

=head2 _LOCK_UNTIL_STABLE

An optional flag set directly on an agent frame:

  $agent->{_LOCK_UNTIL_STABLE} = 'Y';

When C<_LOCK_UNTIL_STABLE> is set on agent N, C<process()> skips that agent in
the current iteration if B<any> earlier agent has already succeeded
(C<_SUCCES> is true on that agent).  This implements priority-based sequencing:
earlier agents are given another full pass before the locked agent is allowed
to run.

Typical use: a "global cleanup" or "conformity check" agent that should only
run once all upstream agents have stabilised for the current cycle.

=head2 _REPLAY and _REPLAY_ALL

These flags are set by the corresponding engine methods and are handled
transparently by C<process()>.

=over 4

=item C<_REPLAY>

Set by C<< $agent->replay() >>.  C<process()> re-runs C<loop()> on the same
agent immediately (inner C<do/while> loop), without advancing to the next agent.

=item C<_REPLAY_ALL>

Set by C<< $agent->replay_all() >>.  C<process()> restarts the outer agent loop
from the beginning — all agents are iterated again from agent 1.

=back

Both flags are automatically deleted by C<process()> before the re-run, so they
fire exactly once per call.

=head1 BOARD

Every agent registered with C<register()> receives a reference to a shared
L<Chorus::Frame> called B<BOARD>.  Access it from inside any rule:

  my $board = $agent->BOARD;

=head2 Reserved slots

=over 4

=item C<SOLVED>

Set to C<'Y'> by C<< $agent->solved() >>.  Causes C<process()> to return C<1>
immediately after the current C<loop()> call finishes.  Deleted by C<process()>
before returning.

=item C<FAILED>

Set to C<'Y'> by C<< $agent->failed() >>.  Causes C<process()> to return
C<undef> immediately.  Deleted by C<process()> before returning.

=item C<INPUT>

Set by C<process($input)> before the main loop starts.  Holds the raw input
value passed to the pipeline.

  my $input = $agent->BOARD->INPUT;

=back

=head2 Custom slots for inter-agent communication

Any other slot can be freely written and read by agents to exchange state that
does not belong to individual domain frames:

  # In agent 1's _APPLY:
  $agent->BOARD->set('phase', 'enrichment');

  # In agent 2's _APPLY:
  my $phase = $agent->BOARD->phase;    # 'enrichment'

Use BOARD for pipeline-level flags and counters.  Domain knowledge (facts about
specific objects) belongs on L<Chorus::Frame> instances, not on the BOARD.

=cut

use Chorus::Frame;

use constant DEFAULT_MAX_ITER => 10_000;

sub new {
  my $class = shift;
  return bless {
    _agents => [],
    _board  => Chorus::Frame->new(),
  }, $class;
}

sub register {
  my $this  = shift;
  my $board = $this->{_board};
  $_->set('BOARD',  $board) for @_;   # BOARD shared between agents of this instance
  $_->set('EXPERT', $this)  for @_;   # each agent can talk back to me
  push @{ $this->{_agents} }, @_;
  return $this;
}

# --

sub debug {
  my ($this, $level) = @_;
  $this->{_DEBUG} = $level;
}

sub process {
  my ($this, $input) = @_;
  my $board   = $this->{_board};
  my $agents  = $this->{_agents};
  $board->set('INPUT', $input);
  my $max_iter = $this->{_MAX_ITER} // DEFAULT_MAX_ITER;
  my $iter = 0;
  do {
       if (++$iter > $max_iter) {
           warn "Chorus::Expert - process() reached max iterations ($max_iter) without SOLVED or FAILED\n";
           return;
       }
       my @processed = ();
       for my $agent (@$agents) {

          if ($agent->_LOCK_UNTIL_STABLE ) {
             print STDERR "Chorus::Expert - Agent $agent->{_IDENT} is tagged with LOCK_UNTIL_STABLE\n" if $this->{_DEBUG};
             last if grep { $_->_SUCCES } @processed;
             print STDERR "Chorus::Expert - None of agents [" . join (',', map { $_->{_IDENT} || 'NO_NAME' } @processed) . "] have succeeded\n" if $this->{_DEBUG};
          }

          do {

            if ($agent->_REPLAY) {
              print STDERR "Chorus::Expert - REPLAYING AGENT $agent->{_IDENT} NOW.\n" if $this->{_DEBUG};
              $agent->delete('_REPLAY');
            }

            print STDERR "Chorus::Expert - LOOPING ON AGENT $agent->{_IDENT} NOW.\n" if $this->{_DEBUG};
            $agent->loop() unless $board->SOLVED or $board->FAILED;

         } while($agent->_REPLAY);

         push @processed, $agent;

          if ($agent->_REPLAY_ALL) {
            print STDERR "Chorus::Expert - WILL REPLAY ALL AGENTS NOW.\n" if $this->{_DEBUG};
            $agent->delete('_REPLAY_ALL');
            last;
          }
       }
  } until ($board->{SOLVED} or $board->{FAILED});

  ($board->delete('SOLVED'), return 1) if $board->{SOLVED};
  ($board->delete('FAILED'), return  ) if $board->{FAILED};
}

=head1 AUTHOR

Christophe Ivorra

=head1 BUGS

B<C<new()> ignores its arguments.>  Parameters passed to C<Chorus::Expert->new()>
(including C<_MAX_ITER>) are silently discarded.  Always set C<_MAX_ITER> by
direct assignment immediately after construction:

  my $xprt = Chorus::Expert->new();
  $xprt->{_MAX_ITER} = 50_000;   # mandatory for long pipelines

The default is 10,000 iterations.  For a pipeline of N frames × M total rules,
a safe heuristic is C<N × M × safety_margin> (typically ×10).

Please report other bugs via the CPAN request tracker:
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Chorus>

=head1 SUPPORT

  perldoc Chorus::Expert

=over 4

=item * RT -- L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Chorus-Expert>

=item * AnnoCPAN -- L<http://annocpan.org/dist/Chorus-Expert>

=item * CPAN Ratings -- L<http://cpanratings.perl.org/d/Chorus-Expert>

=item * Search CPAN -- L<http://search.cpan.org/dist/Chorus-Expert/>

=back

=head1 SEE ALSO

L<Chorus::Frame>, L<Chorus::Engine>

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Christophe Ivorra.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut

END { }

1; # End of Chorus::Expert
