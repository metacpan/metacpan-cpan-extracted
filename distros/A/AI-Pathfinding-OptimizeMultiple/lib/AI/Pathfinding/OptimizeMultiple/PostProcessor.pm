package AI::Pathfinding::OptimizeMultiple::PostProcessor;
$AI::Pathfinding::OptimizeMultiple::PostProcessor::VERSION = '0.0.17';
use strict;
use warnings;

use 5.012;

use MooX qw/late/;

has _should_do_rle =>
    ( isa => 'Bool', is => 'ro', init_arg => 'do_rle', required => 1 );
has _offset_quotas => (
    isa      => 'Bool',
    is       => 'ro',
    init_arg => 'offset_quotas',
    required => 1
);

sub scans_rle
{
    my $self = shift;

    my @scans_list = @{ shift() };

    my $scan = shift(@scans_list);

    my (@a);
    while ( my $next_scan = shift(@scans_list) )
    {
        if ( $next_scan->scan_idx() == $scan->scan_idx() )
        {
            $scan->iters( $scan->iters() + $next_scan->iters() );
        }
        else
        {
            push @a, $scan;
            $scan = $next_scan;
        }
    }
    push @a, $scan;
    return \@a;
}

sub process
{
    my $self = shift;

    my $scans_orig = shift;

    # clone the scans.
    my $scans = [ map { $_->clone(); } @{$scans_orig} ];

    if ( $self->_offset_quotas )
    {
        $scans = [
            map {
                my $ret = $_->clone();
                $ret->iters( $ret->iters() + 1 );
                $ret;
            } @$scans
        ];
    }

    if ( $self->_should_do_rle )
    {
        $scans = $self->scans_rle($scans);
    }

    return $scans;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AI::Pathfinding::OptimizeMultiple::PostProcessor - post-processor.

=head1 VERSION

version 0.0.17

=head1 SUBROUTINES/METHODS

=head2 $self->scans_rle()

For internal use.

=head2 $self->process($scans_orig)

For internal use.

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
