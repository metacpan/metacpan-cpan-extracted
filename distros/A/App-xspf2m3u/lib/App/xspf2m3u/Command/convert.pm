package App::xspf2m3u::Command::convert;
$App::xspf2m3u::Command::convert::VERSION = '0.0.2';
use strict;
use warnings;
use autodie;
use 5.016;

use Path::Tiny qw/ path /;

use App::xspf2m3u -command;
use XML::XSPF ();

{
    no warnings 'redefine';
    *XML::XSPF::_isValidURI = sub { return 1; };
}
sub abstract { "convert .xspf playlists to .m3u ones" }

sub description { return abstract(); }

sub opt_spec
{
    return ( [ "output|o=s", "Output path" ], );
}

sub validate_args
{
    my ( $self, $opt, $args ) = @_;

    $self->usage_error("args required")            if not @$args;
    $self->usage_error("can only accept one path") if @$args != 1;
}

sub execute
{
    my ( $self, $opt, $args ) = @_;

    my $playlist = XML::XSPF->parse( $args->[0] );

    my $text = '';
    foreach my $track ( $playlist->trackList )
    {
        if ( my $loc = $track->location )
        {
            if ( $loc =~ /[\n\r]/ )
            {
                die "Invalid newline in location <<$loc>>!";
            }
            $text .= "$loc\n";
        }
    }
    path( $opt->{output} )->spew_utf8($text);

    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 VERSION

version 0.0.2

=for :stopwords cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/App-xspf2m3u>

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/App-xspf2m3u>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-xspf2m3u>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/App-xspf2m3u>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/App-xspf2m3u>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/A/App-xspf2m3u>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=App-xspf2m3u>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=App::xspf2m3u>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-app-xspf2m3u at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=App-xspf2m3u>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/shlomif/App-xspf2m3u>

  git clone https://github.com/shlomif/App-xspf2m3u.git

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/shlomif/app-xspf2m3u/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=cut
