package Data::AnyXfer::Elastic::Import::Storage::LzmaFile;

# IMPORTS
use Moo;
use MooX::Types::MooseLike::Base qw(:all);


use Carp;
use IO::Compress::Lzma qw( $LzmaError );
use IO::Uncompress::UnLzma qw( $UnLzmaError );

extends 'Data::AnyXfer::Elastic::Import::Storage::TarFile';

# CONSUME STORAGE ROLE
with 'Data::AnyXfer::Elastic::Import::Storage';

=head1 NAME

Data::AnyXfer::Elastic::Import::Storage::LzmaFile

=head1 DESCRIPTION

This module implements is an extension of L<Data::AnyXfer::Elastic::Import::Storage::TarFile>,
an compresses files using I<IO::Compress::Lzma>.

See C<Data::AnyXfer::Elastic::Import::Storage::TarFile> for more details.

=cut



# METHOD OVERRIDING

sub get_fh {
    my ( $self, $mode ) = @_;
    return $self->_get_fh_write if $mode eq 'w';
    return $self->_get_fh_read  if $mode eq 'r';
    return undef;
}


# PRIVATE METHODS

sub _get_fh_write {
    IO::Compress::Lzma->new( $_[0]->file->openw )
        or croak "Lzma write compression failed: $LzmaError\n";
}

sub _get_fh_read {
    IO::Uncompress::UnLzma->new( $_[0]->file->openr )
        or croak "Lzma read compression failed: $UnLzmaError\n";
}

1;

=head1 COPYRIGHT

This software is copyright (c) 2019, Anthony Lucas.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut

