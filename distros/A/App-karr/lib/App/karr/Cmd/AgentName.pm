# ABSTRACT: Print a claim name derived from the checkout directory

package App::karr::Cmd::AgentName;
our $VERSION = '0.601';
use Moo;
use MooX::Cmd;
use MooX::Options (
  usage_string => 'USAGE: karr agentname [--unique]',
);
use App::karr::AgentName qw( agent_name );
use App::karr::Role::CliArgs;
use App::karr::Role::ExitCodes;
use App::karr::Role::Output;

# Unknown option / bad option value exits 2, not 1 (ADR 0002 exit-code
# contract). This board-less command has no BoardDiscovery to inherit it from.
with 'App::karr::Role::CliArgs';
with 'App::karr::Role::ExitCodes';
with 'App::karr::Role::Output';


option unique => (
  is  => 'ro',
  doc => 'Append a short random suffix, to tell apart agents in one directory',
);

sub execute {
  my ($self, $args_ref, $chain_ref) = @_;

  my $name = agent_name( unique => $self->unique );
  if ($self->json) {
    $self->print_json( { name => $name } );
  } else {
    print "$name\n";
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::Cmd::AgentName - Print a claim name derived from the checkout directory

=head1 VERSION

version 0.601

=head1 SYNOPSIS

    # The claim name for this checkout -- stable, so every call agrees:
    karr agent-name                 # -> karr, graphify-fix, wt1, ...

    # Export it once; every nested karr call in the session claims as it:
    export KARR_CLAIM=$(karr agent-name)
    karr pick --move in-progress
    karr handoff 7 --note "Implementation complete"

    # Several agents in ONE directory: a random suffix keeps them apart.
    export KARR_CLAIM=$(karr agent-name --unique)   # -> karr-8fa

=head1 DESCRIPTION

Prints a claim-safe name for the current checkout: the worktree root's
directory name, lowercased with every run of non-C<[a-z0-9]> characters folded
to a single C<-> and the ends trimmed. The agent working the C<karr> checkout
is C<karr>; the one in a worktree at C<.../graphify-fix> is C<graphify-fix>. The
source is the worktree root (libgit2's C<workdir>, what C<git rev-parse
--show-toplevel> reports), so it does not matter which subdirectory the command
runs in; outside a work tree it falls back to the current directory's basename.

ADR 0005 makes this the value C<KARR_CLAIM> carries. Every command that takes
C<--claim> (L<App::karr::Cmd::Move>, L<App::karr::Cmd::Handoff>,
L<App::karr::Cmd::Pick>, L<App::karr::Cmd::Edit>, L<App::karr::Cmd::Create>) and
C<karr list --claimed-by> defaults to C<$KARR_CLAIM> when the flag is omitted,
so the recommended shape is to export it once per session:

    export KARR_CLAIM=$(karr agent-name)

rather than passing C<--claim NAME> on every call. An explicit C<--claim> still
wins over the environment for a one-off.

The name is now B<stable> per checkout, not the random word it used to be: it
is meaningful in C<karr show>, and distinct per worktree without a generator.
The recommended way to run several agents on one board is therefore one
worktree each -- their directory names already differ, so their claims differ.

=head2 --unique

The one case a directory name cannot tell apart is several agents started in
the B<same> directory: they would all get the same name and, because claims
match by name, stamp and hand off over each other. C<--unique> appends a short
random suffix -- C<karr-8fa> -- keeping the checkout identity visible while
making each agent distinct. Captured once into C<KARR_CLAIM>, the suffix is
stable for that session. This is where the old random-name behaviour now lives.

=head1 OPTIONS

=over 4

=item * C<--unique>

Append a short random suffix to the checkout name, for several agents sharing
one directory.

=item * C<--json>

Emit the name as one JSON object -- C<{"name":"..."}> -- and nothing else on
stdout, so a caller can capture the name without trimming a trailing newline.

=back

=head1 SEE ALSO

L<karr>, L<App::karr>, L<App::karr::AgentName>, L<App::karr::Cmd::Pick>,
L<App::karr::Cmd::Handoff>, L<App::karr::Role::ClaimDefault>

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
