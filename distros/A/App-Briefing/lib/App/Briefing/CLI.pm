package App::Briefing::CLI;
# ABSTRACT: Retired stub, see App::Briefing

use strict;
use warnings;

our $VERSION = '0.007000';

our $NOTICE = q{briefing is retired: Claude Code now preloads agent skills natively. Replace the `briefing:` block in an agent's frontmatter by a top-level `skills:` list, then run `/plugin uninstall briefing`. How: https://code.claude.com/docs/en/sub-agents#preload-skills-into-subagents};

sub run {
  print STDERR "$NOTICE\n";
  return 1;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Briefing::CLI - Retired stub, see App::Briefing

=head1 VERSION

version 0.007000

=head1 DESCRIPTION

A stub: briefing is retired. L<App::Briefing> names the replacement.

=head2 run

    exit App::Briefing::CLI->run(\@ARGV);

Prints the retirement notice to standard error and returns 1. A C<briefing>
command left over from an earlier release calls this and so says what to do.

=head1 SEE ALSO

=over

=item * L<App::Briefing>

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
