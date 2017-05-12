package AI::Pathfinding::OptimizeMultiple::Scan;
$AI::Pathfinding::OptimizeMultiple::Scan::VERSION = '0.0.15';
use strict;
use warnings;

use 5.012;

use MooX qw/late/;

has cmd_line => (isa => 'Str', is => 'ro', required => 1,);
has id => (isa => 'Str', is => 'ro', required => 1,);
has used => (isa => 'Bool', is => 'rw', default => sub { 0; });

sub mark_as_used
{
    my $self = shift;
    $self->used(1);
}

sub is_used
{
    my $self = shift;
    return $self->used();
}


sub data_file_path
{
    my $self = shift;

    return "./data/" . $self->id() .  ".data.bin";
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AI::Pathfinding::OptimizeMultiple::Scan

=head1 VERSION

version 0.0.15

=head1 VERSION

version 0.0.15

=head1 SLOTS

=head2 $scan->cmd_line()

The command line string, which defines the scan's behaviour - required upon
initialization.

=head2 $scan->id()

The scan ID - a string.

=head2 $scan->used()

A boolean - whether the scan was used.

=head1 METHODS

=head2 $self->mark_as_used()

Mark the scan as used.

=head2 $self->is_used()

Returns whether the scan was used.

=head2 $scan->data_file_path()

Returns the path to the data file of the scan, where the numbers of iterations
per board are stored.

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/shlomif/ai-pathfinding-optimizemultiple/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc AI::Pathfinding::OptimizeMultiple

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<http://metacpan.org/release/AI-Pathfinding-OptimizeMultiple>

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/AI-Pathfinding-OptimizeMultiple>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=AI-Pathfinding-OptimizeMultiple>

=item *

AnnoCPAN

The AnnoCPAN is a website that allows community annotations of Perl module documentation.

L<http://annocpan.org/dist/AI-Pathfinding-OptimizeMultiple>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/AI-Pathfinding-OptimizeMultiple>

=item *

CPAN Forum

The CPAN Forum is a web forum for discussing Perl modules.

L<http://cpanforum.com/dist/AI-Pathfinding-OptimizeMultiple>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/AI-Pathfinding-OptimizeMultiple>

=item *

CPAN Testers

The CPAN Testers is a network of smokers who run automated tests on uploaded CPAN distributions.

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

=cut
