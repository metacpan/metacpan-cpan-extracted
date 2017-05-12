package App::Wx::PodEditor;

use warnings;
use strict;

use Wx;

use App::Wx::PodEditor::Frame;

our @ISA = qw(Wx::App);

our $VERSION = '0.01';

sub OnInit {
    my ( $self ) = @_;
    
    my( $frame ) = App::Wx::PodEditor::Frame->new( undef, -1, "PodEditor", [20,20], [500,340] );
    $frame->Show(1);
    
    1;
}

1;

=head1 NAME

App::Wx::PodEditor - A Pod editor written with wxPerl

=head1 SYNOPSIS

Perhaps a little code snippet.

    use App::Wx::PodEditor;

    my $foo = App::Wx::PodEditor->new();
    $foo->MainLoop;

=head1 AUTHOR

Renee Baecker, C<< <module at renee-baecker.de> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-app-wx-podeditor at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App::Wx::PodEditor>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::Wx::PodEditor

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App::Wx::PodEditor>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App::Wx::PodEditor>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App::Wx::PodEditor>

=item * Search CPAN

L<http://search.cpan.org/dist/App::Wx::PodEditor>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2008 Renee Baecker, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of App::Wx::PodEditor
