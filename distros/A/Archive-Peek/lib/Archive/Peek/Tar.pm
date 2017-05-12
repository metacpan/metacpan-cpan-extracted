package Archive::Peek::Tar;
use Moose;
use Archive::Tar;
extends 'Archive::Peek';

sub tar {
    my $self     = shift;
    my $filename = $self->filename;

    my $tar = Archive::Tar->new( $filename->stringify )
        || confess("Error reading $filename");
    return $tar;
}

sub files {
    my $self = shift;
    my $tar  = $self->tar;

    my @files
        = sort map { $_->full_path } grep { $_->is_file } $tar->get_files();
    return @files;
}

sub file {
    my ( $self, $filename ) = @_;
    my $tar = $self->tar;

    return $tar->get_content($filename);
}

1;
