package App::ManiacDownloader::_BytesDownloaded;
$App::ManiacDownloader::_BytesDownloaded::VERSION = '0.0.13';
use strict;
use warnings;

use MooX qw/late/;

use List::Util qw/min/;

has [ '_bytes_dled', '_bytes_dled_last_timer' ] =>
    ( isa => 'Int', is => 'rw', default => sub { return 0; } );

has '_stale_checkpoints_count' => (
    isa     => 'Int',
    is      => 'rw',
    default => sub { return 0; }
);

sub _add
{
    my ( $self, $num_written ) = @_;

    $self->_bytes_dled( $self->_bytes_dled + $num_written, );

    return;
}

sub _total_downloaded
{
    my ($self) = @_;

    return $self->_bytes_dled;
}

sub _were_stale_checkpoints_exceeded
{
    my ( $self, $MAX_COUNT ) = @_;

    return ( $self->_stale_checkpoints_count >= $MAX_COUNT );
}

sub _flush_and_report
{
    my $self = shift;

    my $difference = $self->_bytes_dled - $self->_bytes_dled_last_timer;

    if ( $difference > 0 )
    {
        $self->_stale_checkpoints_count(0);
    }
    else
    {
        $self->_stale_checkpoints_count( $self->_stale_checkpoints_count + 1 );
    }

    $self->_bytes_dled_last_timer( $self->_bytes_dled );

    return ( $difference, $self->_bytes_dled );
}

sub _my_init
{
    my ( $self, $num_bytes ) = @_;

    $self->_bytes_dled($num_bytes);
    $self->_bytes_dled_last_timer($num_bytes);

    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 VERSION

version 0.0.13

=for :stopwords cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/App-ManiacDownloader>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-ManiacDownloader>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/App-ManiacDownloader>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/A/App-ManiacDownloader>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=App-ManiacDownloader>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=App::ManiacDownloader>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-app-maniacdownloader at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=App-ManiacDownloader>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/shlomif/maniac-downloader>

  git clone git://github.com/shlomif/maniac-downloader.git

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/shlomif/maniac-downloader/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=cut
