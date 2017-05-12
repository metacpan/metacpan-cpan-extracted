package Archive::Peek::Zip;
use Moose;
use Archive::Zip qw(AZ_OK);
use Archive::Zip::MemberRead;
extends 'Archive::Peek';

sub zip {
    my $self     = shift;
    my $filename = $self->filename;
    my $zip      = Archive::Zip->new();
    unless ( $zip->read( $filename->stringify ) == AZ_OK ) {
        confess("Error reading $filename");
    }
    return $zip;
}

sub files {
    my $self = shift;
    my $zip  = $self->zip;

    my @members = $zip->members();
    my @files = sort map { $_->fileName } grep { !$_->isDirectory } @members;
    return @files;
}

sub file {
    my ( $self, $filename ) = @_;
    my $zip = $self->zip;

    my $fh = Archive::Zip::MemberRead->new( $zip, $filename );
    my $file = '';
    while (1) {
        my $read = $fh->read( my $buffer, 1024 );
        die "FATAL ERROR reading my secrets !\n" if ( !defined($read) );
        last if ( !$read );
        $file .= $buffer;
    }
    return $file;
}

1;
