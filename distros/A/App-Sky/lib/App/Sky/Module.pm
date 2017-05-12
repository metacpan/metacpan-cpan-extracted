package App::Sky::Module;

use strict;
use warnings;

our $VERSION = '0.2.1';


use Carp ();

use Moo;
use MooX 'late';

use URI;
use File::Basename qw(basename);

use List::MoreUtils qw( uniq );

use App::Sky::Results;
use App::Sky::Exception;

has base_upload_cmd => (isa => 'ArrayRef[Str]', is => 'ro',);
has dest_upload_prefix => (isa => 'Str', is => 'ro',);
has dest_upload_url_prefix => (isa => 'Str', is => 'ro',);


sub get_upload_results
{
    my ($self, $args) = @_;

    my $is_dir = ($args->{is_dir} // 0);

    my $filenames = $args->{filenames}
        or Carp::confess ("Missing argument 'filenames'");

    if (@$filenames != 1)
    {
        Carp::confess ("More than one file passed to 'filenames'");
    }

    my $target_dir = $args->{target_dir}
        or Carp::confess ("Missing argument 'target_dir'");

    my $invalid_chars_re = qr/[:]/;

    my @invalid_chars = (map { split( //, $_) } map { /($invalid_chars_re)/g } @$filenames);

    if (@invalid_chars)
    {
        App::Sky::Exception::Upload::Filename::InvalidChars->throw(
            invalid_chars =>
            [sort { $a cmp $b } uniq(@invalid_chars)],
        );
    }

    return App::Sky::Results->new(
        {
            upload_cmd =>
            [
                @{$self->base_upload_cmd()},
                @$filenames,
                ($self->dest_upload_prefix() . $target_dir),
            ],
            urls =>
            [
                URI->new(
                    $self->dest_upload_url_prefix()
                    . $target_dir
                    . basename($filenames->[0])
                    . ($is_dir ? '/' : '')
                ),
            ],
        }
    );
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Sky::Module - class that does the heavy lifting.

=head1 VERSION

version 0.2.1

=head1 METHODS

=head2 $sky->base_upload_cmd()

Returns an array reference of strings of the upload command.

=head2 $sky->dest_upload_prefix

The upload prefix to upload to. So:

    my $m = App::Sky::Module->new(
        {
            base_upload_cmd => [qw(rsync -a -v --progress --inplace)],
            dest_upload_prefix => 'hostgator:public_html/',
            dest_upload_url_prefix => 'http://www.shlomifish.org/',
        }
    );

=head2 $sky->dest_upload_url_prefix

The base URL where the uploads will be found.

=head2 my $results = $sky->get_upload_results({ filenames => ["Shine4U.webm"], target_dir => "Files/files/video/" });

Gives the recipe to execute for the upload commands.

Returns a L<App::Sky::Results> reference containing:

=over 4

=item * upload_cmd

The upload command to execute (as an array reference of strings).

=back

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-Sky or by email to
bug-app-sky@rt.cpan.org.

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc App::Sky

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<http://metacpan.org/release/App-Sky>

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/App-Sky>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-Sky>

=item *

AnnoCPAN

The AnnoCPAN is a website that allows community annotations of Perl module documentation.

L<http://annocpan.org/dist/App-Sky>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/App-Sky>

=item *

CPAN Forum

The CPAN Forum is a web forum for discussing Perl modules.

L<http://cpanforum.com/dist/App-Sky>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.perl.org/dist/overview/App-Sky>

=item *

CPAN Testers

The CPAN Testers is a network of smokers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/A/App-Sky>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=App-Sky>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=App::Sky>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-app-sky at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-Sky>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/shlomif/Sky-uploader>

  git clone git://github.com/shlomif/Sky-uploader.git

=cut
