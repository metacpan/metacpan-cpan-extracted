package CAM::PDF::Renderer::Dump;

use 5.006;
use warnings;
use strict;
use base qw(CAM::PDF::GS);

our $VERSION = '1.60';

=head1 NAME

CAM::PDF::Renderer::Dump - Print the graphic state of each node

=head1 LICENSE

See CAM::PDF.

=head1 SYNOPSIS

    use CAM::PDF;
    my $pdf = CAM::PDF->new($filename);
    my $contentTree = $pdf->getPageContentTree(4);
    $contentTree->render("CAM::PDF::Renderer::Dump");

=head1 DESCRIPTION

This class is used to print to STDOUT the coordinates of each node of
a page layout.  It is written both for debugging and as a minimal
example of a renderer.

=head1 FUNCTIONS

=over

=item $self->renderText($string)

Prints the string prefixed by its device and user coordinates.

=cut

sub renderText
{
   my $self = shift;
   my $string = shift;

   my ($xu, $yu) = $self->textToUser(0, 0);
   my ($xd, $yd) = $self->userToDevice($xu, $yu);

   printf "(%7.2f,%7.2f) (%7.2f,%7.2f) %s\n", $xd,$yd,$xu,$yu, $string;
   return;
}

1;
__END__

=back

=head1 AUTHOR

See L<CAM::PDF>

=cut
