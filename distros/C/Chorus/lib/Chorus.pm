package Chorus;

use 5.006;
use strict;
use warnings;

our $VERSION = '2.0.1';

=encoding UTF-8

=head1 NAME

Chorus - Perl inference engine and AI-assisted compliance-checking platform

=head1 VERSION

2.0.1

=head1 DESCRIPTION

Chorus is a symbolic inference platform that turns normative corpora into
deterministic, reproducible compliance-checking pipelines.

The distribution ships three layers:

=over 4

=item * B<Inference engine> — L<Chorus::Engine>, L<Chorus::Expert>,
L<Chorus::Frame>, L<Chorus::Collection::List>, L<Chorus::Collection::Filter>:
the Perl classes that implement the recognise-act cycle over typed frames.
Rules are written in Perl via C<addrule()> or in a compact YAML DSL via
C<loadRules()>.

=item * B<AI agent companion> — an C<agent/> directory (skills and knowledge
templates) that drives an AI agent (Claude, Copilot, ECA…) to extract rules
from a corpus and generate a complete compliance pipeline.  The AI is only
involved in the knowledge-formalisation phase; the engine then runs
deterministically — no LLM, no network.

=item * B<YAML DSL> — a declarative rule language understood by
L<Chorus::Engine>; see L<Chorus::Engine/"YAML DSL">.

=back

See L<Chorus::Engine::AIAgent> for the full corpus-to-compliance workflow.

=head1 SEE ALSO

L<Chorus::Engine>, L<Chorus::Expert>, L<Chorus::Frame>,
L<Chorus::Collection::List>, L<Chorus::Collection::Filter>,
L<Chorus::Engine::AIAgent>

=head1 AUTHOR

Christophe Ivorra E<lt>ch.ivorra@free.frE<gt>

=head1 BUGS

Please report bugs via the CPAN request tracker:
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Chorus>

=head1 SUPPORT

=over 4

=item * RT -- L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Chorus>

=item * MetaCPAN -- L<https://metacpan.org/dist/Chorus>

=item * GitHub -- L<https://github.com/civorra/Chorus>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2013-2026 Christophe Ivorra.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut

1;
