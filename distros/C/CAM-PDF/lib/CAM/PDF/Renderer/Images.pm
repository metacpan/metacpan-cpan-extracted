package CAM::PDF::Renderer::Images;

use 5.006;
use warnings;
use strict;

our $VERSION = '1.60';

=for stopwords inline

=head1 NAME

CAM::PDF::Renderer::Images - Find all of the images in a page

=head1 LICENSE

See CAM::PDF.

=head1 SYNOPSIS

    use CAM::PDF;
    my $pdf = CAM::PDF->new($filename);
    my $contentTree = $pdf->getPageContentTree(4);
    my $gs = $contentTree->findImages();
    my @imageNodes = @{$gs->{images}};

=head1 DESCRIPTION

This class is used to identify all image nodes in a page content tree.

=head1 FUNCTIONS

=over

=item $self->new()

Creates a new renderer.

=cut

sub new
{
   my $pkg = shift;
   return bless {
      images => [],
   }, $pkg;
}

=item $self->clone()

Duplicates an instance.  The new instance deliberately shares its
C<images> property with the original instance.

=cut

sub clone
{
   my $self = shift;

   my $pkg = ref $self;
   my $new_self = $pkg->new();
   $new_self->{images} = $self->{images};
   return $new_self;
}

=item $self->Do(DATA...)

Record an indirect image node.

=cut

sub Do
{
   my ($self, @rest) = @_;
   my $value = [@rest];

   push @{$self->{images}}, {
      type => 'Do',
      value => $value,
   };
   return;
}

=item $self->BI(DATA...)

Record an inline image node.

=cut

sub BI
{
   my ($self, @rest) = @_;
   my $value = [@rest];

   push @{$self->{images}}, {
      type => 'BI',
      value => $value,
   };
   return;
}

1;
__END__

=back

=head1 AUTHOR

See L<CAM::PDF>

=cut
