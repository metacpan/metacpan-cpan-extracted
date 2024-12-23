package App::Sky;
$App::Sky::VERSION = '0.6.0';
use strict;
use warnings;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Sky - wrapper to rsync/etc. to upload files to a remote server and give
download links.

=head1 VERSION

version 0.6.0

=head1 SYNOPSIS

Put something like this in F<~/.config/Perl/App-Sky/app_sky_conf.yml> :

    ---
    default_site: homepage
    sites:
        homepage:
            base_upload_cmd:
                - 'rsync'
                - '-a'
                - '-v'
                - '--progress'
                - '--inplace'
            dest_upload_prefix: 'hostgator:public_html/'
            dest_upload_url_prefix: 'http://www.shlomifish.org/'
            sections:
                code:
                    basename_re: '\.(?:pl|pm|c|py)\z'
                    target_dir: 'Files/files/code/'
                music:
                    basename_re: '\.(?:mp3|ogg|wav|aac|m4a)\z'
                    target_dir: 'Files/files/music/mp3-ogg/'
                video:
                    basename_re: '\.(?:webm|flv|avi|mpeg|mpg|mp4|ogv)\z'
                    target_dir: 'Files/files/video/'

Then you can use commands such as:

    $ sky up /path/to/my-music-file.mp3

And get in return a URL to where it was uploaded.

=for :stopwords cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/App-Sky>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-Sky>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/App-Sky>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

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
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=App-Sky>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/shlomif/Sky-uploader>

  git clone git://github.com/shlomif/Sky-uploader.git

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/shlomif/Sky-uploader/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=cut
