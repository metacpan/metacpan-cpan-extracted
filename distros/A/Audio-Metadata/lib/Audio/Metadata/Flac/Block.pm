package Audio::Metadata::Flac::Block;
{
  $Audio::Metadata::Flac::Block::VERSION = '0.16';
}
BEGIN {
  $Audio::Metadata::Flac::Block::VERSION = '0.15';
}

use strict;
use warnings;
use autodie;

use Any::Moose;
use Module::Find ();
use List::Util qw/first/;


has _init_content  => ( isa => 'Str', is => 'ro', );
has next           => ( isa => 'Maybe[Audio::Metadata::Flac::Block]', is => 'rw', );


__PACKAGE__->meta->make_immutable;


sub BUILDARGS {
    ## Populates attrbutes on creation of block object.
    my $self = shift;

    # Only accept single scalar parameter as initial content.
    return {
        _init_content => $_[0],
    };
}


sub new_from_fh {
    ## Reads block from given filehandle and returns object of appropriate type and
    ## is_last flag, which is true if more blocks follow.
    my $class = shift;
    my ($fh) = @_;

    # Read header.
    $fh->read(my $header, $class->header_size);

    # Parse header.
    my $first_byte = unpack('C', $header);
    my $is_last = ($first_byte & 0b10000000) > 0;
    my $type = $first_byte & 0b01111111;
    my $content_size = unpack('N', chr(0) . substr($header, 1)); # 24-bit long

    # Find submodule for block with this type code.
    my $block_class = first { $_->type_code == $type } Module::Find::useall(__PACKAGE__)
        or die "Don't know how to handle block of type \"$type\"";

    # Read content, instantiate block object and return it.
    $fh->read(my $content, $content_size);
    return ( $block_class->new($content), $is_last );
}


sub _get_header {
    ## Returns packed block header.
    my $self = shift;

    my $first_byte = $self->type_code;
    $first_byte |= 0b10000000 unless $self->next;
    my $header = chr($first_byte) . substr(pack('N', $self->content_size), 1);
    return $header;
}


sub content_as_string {
    ## Returns block content as string, taking into account unsaved changes in block
    ## structures.
    my $self = shift;

    return $self->_init_content;
}


sub as_string {
    ## Returns complete block as string, including header.
    my $self = shift;

    return $self->_get_header . $self->content_as_string;
}


sub content_size {
    ## Returns size of block content.
    my $self = shift;

    return length($self->content_as_string || '');
}


sub size {
    ## Returns total block size, including header.
    my $self = shift;

    return $self->content_size + $self->header_size;
}


sub header_size {
    ## Returns size of block header.

    4;
}


no Any::Moose;


1;


__END__

=head1 NAME

Audio::Metadata::Flac::Block - Base class for representation FLAC metadata blocks.

=head1 DESCRIPTION

For internal use only by L<Audio::Metadata::Flac>.

=head1 AUTHOR

Egor Shipovalov, C<< <kogdaugodno at gmail.com> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Egor Shipovalov.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
