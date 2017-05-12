package App::ManiacDownloader::_SegmentTask;

use strict;
use warnings;

use MooX qw/late/;

use List::Util qw/min/;

has ['_start', '_end'] => (is => 'rw', isa => 'Int',);
has '_fh' => (is => 'rw',);
has 'is_active' => (is => 'rw', isa => 'Bool', default => 1);
has '_downloaded' => (is => 'rw', isa => 'App::ManiacDownloader::_BytesDownloaded', default => sub { return App::ManiacDownloader::_BytesDownloaded->new; }, handles => ['_flush_and_report'],);
has '_active_seq' => (is => 'rw', isa => 'Int', default => 0);

has '_guard' => (is => 'rw');

has '_count_checks_without_download' => (is => 'rw', isa => 'Int', default => 0);

sub _serialize
{
    my ($self) = @_;

    return
    +{
        _start => $self->_start,
        _end => $self->_end,
        is_active => $self->is_active,
    };
}

sub _deserialize
{
    my ($self, $record) = @_;

    $self->_start($record->{_start});
    $self->_end($record->{_end});
    $self->is_active($record->{is_active});

    return;
}

sub _write_data
{
    my ($self, $data_ref) = @_;

    my $written = syswrite($self->_fh, $$data_ref);
    if ($written != length($$data_ref))
    {
        die "Written bytes mismatch.";
    }

    $self->_downloaded->_add($written);

    my $init_start = $self->_start;
    $self->_start($init_start + $written);

    $self->_count_checks_without_download(0);

    return
    {
        should_continue => scalar($self->_start < $self->_end),
        num_written => (min($self->_start, $self->_end) - $init_start),
    };
}

sub _close
{
    my ($self) = @_;
    close($self->_fh);
    $self->_fh(undef());
    $self->is_active(0);
    $self->_guard('');

    return;
}

sub _num_remaining
{
    my $self = shift;

    return $self->_end - $self->_start;
}

sub _split_into
{
    my ($self,$other) = @_;

    $other->_start(( $self->_start+$self->_end ) >> 1);
    $other->_end($self->_end);
    $self->_end($other->_start);

    return;
}

sub _increment_check_count
{
    my ($self, $max_checks) = @_;

    $self->_count_checks_without_download(
        $self->_count_checks_without_download() + 1
    );

    return ($self->_count_checks_without_download >= $max_checks);
}

sub _get_next_active_seq
{
    my ($self) = @_;

    return $self->_active_seq($self->_active_seq() + 1);
}

sub _is_right_active_seq
{
    my ($self, $right_active_seq) = @_;

    return ($self->_active_seq() == $right_active_seq);
}

1;

__END__

=pod

=encoding UTF-8

=head1 VERSION

version 0.0.12

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-ManiacDownloader or by email
to bug-app-maniacdownloader@rt.cpan.org.

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc App::ManiacDownloader

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<http://metacpan.org/release/App-ManiacDownloader>

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/App-ManiacDownloader>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-ManiacDownloader>

=item *

AnnoCPAN

The AnnoCPAN is a website that allows community annotations of Perl module documentation.

L<http://annocpan.org/dist/App-ManiacDownloader>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/App-ManiacDownloader>

=item *

CPAN Forum

The CPAN Forum is a web forum for discussing Perl modules.

L<http://cpanforum.com/dist/App-ManiacDownloader>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.perl.org/dist/overview/App-ManiacDownloader>

=item *

CPAN Testers

The CPAN Testers is a network of smokers who run automated tests on uploaded CPAN distributions.

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
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-ManiacDownloader>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<http://bitbucket.org/shlomif/perl-App-ManiacDownloader>

  hg clone ssh://hg@bitbucket.org/shlomif/perl-App-ManiacDownloader

=cut
