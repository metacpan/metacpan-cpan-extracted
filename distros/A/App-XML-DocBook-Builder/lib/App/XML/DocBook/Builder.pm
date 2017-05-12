package App::XML::DocBook::Builder;

use warnings;
use strict;

use 5.008;

use parent 'Class::Accessor';

=head1 NAME

App::XML::DocBook::Builder - Build DocBook/XML files.

=head1 VERSION

Version 0.0404

=cut

our $VERSION = '0.0404';

=head1 SYNOPSIS

    use App::XML::DocBook::Builder;

    my $foo = App::XML::DocBook::Builder->new();

=cut

my $inst_dir = "$ENV{HOME}/apps/docbook-builder";

=head1 FUNCTIONS

=head2 initialize_makefiles($args)

Initialize the makefile in the directory.

Accepts one named argument which is "doc_base" for the document base name.

=cut

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

=cut

1; # End of App::XML::DocBook::Builder
