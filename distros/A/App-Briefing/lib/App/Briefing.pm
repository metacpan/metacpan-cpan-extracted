package App::Briefing;
# ABSTRACT: Retired: Claude Code preloads agent skills natively

use strict;
use warnings;

our $VERSION = '0.007000';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Briefing - Retired: Claude Code preloads agent skills natively

=head1 VERSION

version 0.007000

=head1 DESCRIPTION

briefing is retired. It put the skills an agent declared into a subagent's
context at spawn time. Claude Code does that itself now: a top-level C<skills:>
list in the agent's frontmatter preloads each named skill, C<plugin:skill> names
included, when the subagent starts. See
L<https://code.claude.com/docs/en/sub-agents#preload-skills-into-subagents>.

Before:

    ---
    name: my-agent
    briefing:
      skills:
        - perl-core
    ---

After:

    ---
    name: my-agent
    skills:
      - perl-core
    ---

Then remove the plugin with C</plugin uninstall briefing>.

This last release of the distribution ships its modules as empty stubs, so an
upgrade replaces the earlier library code.

=head1 SEE ALSO

=over

=item * L<https://code.claude.com/docs/en/sub-agents#preload-skills-into-subagents>

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests at
L<https://github.com/Getty/briefing/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
