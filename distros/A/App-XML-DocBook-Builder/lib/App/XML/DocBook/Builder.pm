package App::XML::DocBook::Builder;
$App::XML::DocBook::Builder::VERSION = '0.0500';
use warnings;
use strict;

use 5.008;

use parent 'Class::Accessor';


my $inst_dir = "$ENV{HOME}/apps/docbook-builder";


sub initialize_makefiles
{
    my $self = shift;

    my $args = shift;

    my $redirect_makefile = "docmake.mak";

    open my $docbook_mak, ">", $redirect_makefile or
        die "Could not open Makefile for writing";

    print $docbook_mak <<"EOF";
DOCBOOK_MAK_PATH = $inst_dir

DOCBOOK_MAK_MAKEFILES_PATH = \$(DOCBOOK_MAK_PATH)/share/make/

include \$(DOCBOOK_MAK_MAKEFILES_PATH)/main-docbook.mak
EOF

    close ($docbook_mak);

    open my $main_mak, ">", "Makefile.main";
    print $main_mak "DOC = " . $args->{doc_base} . "\n\ninclude $redirect_makefile\n\n";
    close ($main_mak);
}


1; # End of App::XML::DocBook::Builder

__END__

=pod

=encoding UTF-8

=head1 NAME

App::XML::DocBook::Builder - Build DocBook/XML files.

=head1 VERSION

version 0.0500

=head1 SYNOPSIS

    use App::XML::DocBook::Builder;

    my $foo = App::XML::DocBook::Builder->new();

=head1 VERSION

version 0.0500

=head1 FUNCTIONS

=head2 initialize_makefiles($args)

Initialize the makefile in the directory.

Accepts one named argument which is "doc_base" for the document base name.

=head1 AUTHOR

Shlomi Fish, C<< <shlomif at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-app-docbook-xml-builder at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App::XML::DocBook::Builder>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::XML::DocBook::Builder

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App::XML::DocBook::Builder>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App::XML::DocBook::Builder>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App::XML::DocBook::Builder>

=item * Search CPAN

L<http://search.cpan.org/dist/App::XML::DocBook::Builder>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2007 Shlomi Fish.

This program is released under the following license: MIT/X11

L<http://www.opensource.org/licenses/mit-license.php>

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<http://rt.cpan.org/Public/Dist/Display.html?Name=App-XML-DocBook-Builder>
or by email to
L<bug-app-xml-docbook-builder@rt.cpan.org|mailto:bug-app-xml-docbook-builder@rt.cpan.org>.

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc App::XML::DocBook::Builder

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/App-XML-DocBook-Builder>

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/App-XML-DocBook-Builder>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-XML-DocBook-Builder>

=item *

AnnoCPAN

The AnnoCPAN is a website that allows community annotations of Perl module documentation.

L<http://annocpan.org/dist/App-XML-DocBook-Builder>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/App-XML-DocBook-Builder>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/App-XML-DocBook-Builder>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/A/App-XML-DocBook-Builder>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=App-XML-DocBook-Builder>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=App::XML::DocBook::Builder>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-app-xml-docbook-builder at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=App-XML-DocBook-Builder>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/shlomif/app-xml-docbook-builder>

  git clone http://bitbucket.org/shlomif/docmake

=cut
