package Data::AnyXfer::Elastic::Import::Storage::TarFile;

use Moo;
use MooX::Types::MooseLike::Base qw(:all);




use Carp;
use Path::Class ( );
use File::Copy ( );
use Archive::Tar::Streamed ( );
use Archive::Tar::File ( );

extends 'Data::AnyXfer::Elastic::Import::Storage::Directory';

# CONSUME STORAGE ROLE
with 'Data::AnyXfer::Elastic::Import::Storage';


=head1 NAME

Data::AnyXfer::Elastic::Import::Storage::TarFile -
Tar-based import storage

=head1 SYNOPSIS

    my $storage =
        Data::AnyXfer::Elastic::Import::Storage::TarFile->new(
        file => Path::Class::file('myfile.tar') );

    $storage->set(
        company => 'Limited',
        address =>
            'Building One, Chiswick Park, 566 Chiswick High Road, London W4 5BE',
        regno => 1680058,
    );

    $storage->save;

=head1 DESCRIPTION

This module implements L<Data::AnyXfer::Elastic::Import::Storage>,
based on L<Archive::Tar::File> tar files.

The tar file is created on
L<Data::AnyXfer::Elastic::Import::Storage/save>.

It represents items as single files within the tar file,
and can only store printable characters
(i.e. any complex content should be serialised to a representable format
before being passed to this module to store).

=cut

=head1 ATTRIBUTES

=over

=item B<file>

Optional. The final file that data should be persisted to.

=back

=head1 STORAGE INTERFACE

B<Please see L<Data::AnyXfer::Elastic::Import::Storage> and
L<Data::AnyXfer::Elastic::Import::Storage::Directory> for the
interface definition and information>.

=cut


# ATTRIBUTES


has file => (
    is      => 'ro',
    isa     => InstanceOf['Path::Class::File'],
    trigger => sub { $_[0]->_init_source_tar_file },
);


# set the destination string to the file path
sub get_destination_info { return shift->file . '' }



# CONSTRUCTOR ROUTINES


sub BUILD {

    my $self = $_[0];

    # load in current directory state
    # from final dir, not temp dir
    $self->reload;
    $self->_init_source_tar_file;
}



# GENERAL STORAGE INTERFACE

=head1 ADDITIONAL METHODS

=cut

sub save {

    my $self = $_[0];

    # we can only save if we have a final destination file set
    if ( $self->file ) {

        # remove any exising files
        $self->file->remove;

        # create final tar file
        my $fh  = $self->get_fh('w');
        my $tar = Archive::Tar::Streamed->new($fh);
        my $file_part;

        foreach ( $self->working_dir->children ) {
            next if $_->is_dir;

            $file_part = Archive::Tar::File->new( file => $_ );
            $file_part->prefix('');
            $tar->add($file_part);
        }

        $fh->close;
        return 1;
    }

    # can't save as this is a temp storage inst
    return 0;
}

=head2 get_fh

Shorthand for C<Path::Class::File::open>

=cut

sub get_fh {
    my ( $self, $mode ) = @_;
    return $self->file->open($mode);
}



# DIRECTORY STORAGE-SPECIFIC METHODS


sub _init_source_tar_file {

    my $self        = $_[0];
    my $working_dir = $self->working_dir;

    # if we have a source file, restore its contents to the working dir
    if ( $self->file && -f $self->file ) {

        my $fh  = $self->get_fh('r');
        my $tar = Archive::Tar::Streamed->new($fh);

        # extract each file record in the tar
        while ( my $file = $tar->next ) {

            $file->extract( $working_dir->file( $file->name ) )
                or croak 'Failed to extract file from source tar: '
                . $file->name;
        }
        $fh->close;
    }

    # reload the storage instance after restoring items
    $self->reload;
    return;
}




1;

=head1 COPYRIGHT

This software is copyright (c) 2019, Anthony Lucas.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut

