package AI::Pathfinding::OptimizeMultiple::SimulationResults;
$AI::Pathfinding::OptimizeMultiple::SimulationResults::VERSION = '0.0.17';
use strict;
use warnings;

use 5.012;

use MooX qw/late/;

has status      => ( isa => 'Str', is => 'ro', required => 1, );
has total_iters => ( isa => 'Int', is => 'ro', required => 1, );
has scan_runs => (
    isa      => 'ArrayRef[AI::Pathfinding::OptimizeMultiple::ScanRun]',
    is       => 'ro',
    required => 1,
);

sub get_total_iters
{
    return shift->total_iters();
}

sub get_status
{
    return shift->status();
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AI::Pathfinding::OptimizeMultiple::SimulationResults - the simulation results.

=head1 VERSION

version 0.0.17

=head1 SYNOPSIS

=head1 DESCRIPTION

A class for simulation results.

=head1 SUBROUTINES/METHODS

=head2 $scan_run->status()

The status.

=head2 $scan_run->total_iters()

The total iterations count so far.

=head2 my $aref = $self->scan_runs()

An array reference of L<AI::Pathfinding::OptimizeMultiple::ScanRun> .

=head2 $self->get_total_iters()

Returns the total iterations.

=head2 $self->get_status()

Returns the status.

=head1 SEE ALSO

L<AI::Pathfinding::OptimizeMultiple> , L<AI::Pathfinding::OptimizeMultiple::ScanRun> .

=head1 AUTHOR

Shlomi Fish, L<http://www.shlomifish.org/> .

=for :stopwords cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/AI-Pathfinding-OptimizeMultiple>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=AI-Pathfinding-OptimizeMultiple>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/AI-Pathfinding-OptimizeMultiple>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/A/AI-Pathfinding-OptimizeMultiple>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=AI-Pathfinding-OptimizeMultiple>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=AI::Pathfinding::OptimizeMultiple>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-ai-pathfinding-optimizemultiple at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=AI-Pathfinding-OptimizeMultiple>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<http://github.com/shlomif/fc-solve>

  git clone ssh://git@github.com/shlomif/fc-solve.git

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/shlomif/fc-solve/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=cut
