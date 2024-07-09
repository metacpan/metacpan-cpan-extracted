package App::XML::DocBook::Builder;
$App::XML::DocBook::Builder::VERSION = '0.1101';
use 5.014;
use strict;
use warnings;
use autodie;

sub new
{
    my $class = shift;

    return bless {}, $class;
}

1;


my $inst_dir = "$ENV{HOME}/apps/docbook-builder";


sub initialize_makefiles
{
    my $self = shift;

    my $args = shift;

    my $redirect_makefile = "docmake.mak";

    open my $docbook_mak, ">", $redirect_makefile;

    print {$docbook_mak} <<"EOF";
DOCBOOK_MAK_PATH = $inst_dir

DOCBOOK_MAK_MAKEFILES_PATH = \$(DOCBOOK_MAK_PATH)/share/make/

include \$(DOCBOOK_MAK_MAKEFILES_PATH)/main-docbook.mak
EOF

    close($docbook_mak);

    open my $main_mak, ">", "Makefile.main";
    print {$main_mak} "DOC = "
        . $args->{doc_base}
        . "\n\ninclude $redirect_makefile\n\n";
    close($main_mak);

    return;
}


1;    # End of App::XML::DocBook::Builder

__END__

=pod

=encoding UTF-8

=head1 NAME

App::XML::DocBook::Builder - Build DocBook/XML files.

=head1 VERSION

version 0.1101

=head1 SYNOPSIS

    use App::XML::DocBook::Builder ();

    my $foo = App::XML::DocBook::Builder->new();

=head1 FUNCTIONS

=head2 new

A constructor.

=head2 initialize_makefiles($args)

Initialize the makefile in the directory.

Accepts one named argument which is "doc_base" for the document base name.

=head1 AUTHOR

Shlomi Fish, C<< <shlomif at cpan.org> >>

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2007 Shlomi Fish.

This program is released under the following license: MIT/X11

L<http://www.opensource.org/licenses/mit-license.php>

=for :stopwords cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/App-XML-DocBook-Builder>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-XML-DocBook-Builder>

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

L<https://github.com/shlomif/docmake>

  git clone git://github.com/shlomif/docmake.git

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/shlomif/docmake/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=cut
