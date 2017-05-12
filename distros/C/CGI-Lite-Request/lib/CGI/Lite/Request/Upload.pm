package CGI::Lite::Request::Upload;

use strict;

use Carp qw(croak carp);

use File::Copy ();
use IO::File ();

=head1 NAME

CGI::Lite::Request::Upload - Upload objects for CGI::Lite

=head1 SYNOPSIS

  $upload = CGI::Lite::Request::Upload->new;
  
  # getters
  $upload->filename;
  $upload->tempname;
  $upload->size;
  $upload->type;
  
  # copy and hard link
  $upload->copy_to('/target/path');
  $upload->link_to('/target/path');
  
  $fh = $upload->fh;
  $content = $upload->slurp;

=head1 DESCRIPTION

These objects are created automatically during the C<parse> of the incoming
request by L<CGI::Lite::Request>, and shouldn't be instantiated directly.

=head1 METHODS

=over

=item new

simple constructor

=cut

sub new { bless { }, $_[0] }

=item filename

returns the filename of the uploaded file

=item tempname

returns the name of the temporary file to which the content has been spooled

=cut

sub filename { $_[0]->{_filename} = $_[1] if $_[1]; $_[0]->{_filename} }
sub tempname { $_[0]->{_tempname} = $_[1] if $_[1]; $_[0]->{_tempname} }

=item size

returns the size of the uploaded file

=item type

returns the MIME type of the file (guessed with L<File::Type>)

=cut

sub size { $_[0]->{_size} = $_[1] if $_[1]; $_[0]->{_size} }
sub type { $_[0]->{_type} = $_[1] if $_[1]; $_[0]->{_type} }

=item copy_to('/path/to/destination')

copies the file to the destination

=cut

sub copy_to {
    my $self = shift;
    return File::Copy::copy( $self->tempname, @_ );
}

=item fh

returns an L<IO::File> object with the temporary file opened read only 

=cut

#==================================================================
# START OF CODE BORROWED FROM Catalyst::Request::Upload
sub fh {
    my $self = shift;
    my $fh = IO::File->new( $self->tempname, IO::File::O_RDONLY );
    
    unless ( defined $fh ) {
        my $filename = $self->tempname;
        croak( "Can't open '$filename': '$!'" );
    }

    return $fh;
}
# END OF BORROWED CODE
#==================================================================

=item link_to('/path/to/destination')

links the temporary file to the destination

=cut

sub link_to {
    my ($self, $target) = @_;
    return CORE::link($self->tempname, $target);
}

=item slurp

reads and returns the contents of the uploaded file

=cut

sub slurp {
    my ($self) = @_;

    my $content;
    my $handle  = $self->fh;

    binmode($handle);
    local $/ = undef;
    $content = <$handle>;

    return $content;
}

1;

=head1 AUTHOR

Richard Hundt <richard NO SPAM AT protea-systems.com>

=head1 SEE ALSO

L<CGI::Lite>, L<File::Type>, L<CGI::Lite::Request>, L<IO::File>

=head1 LICENCE

This library is free software and may be used under the same terms as Perl itself

=cut

