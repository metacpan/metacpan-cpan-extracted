package Audio::Metadata::Flac::Block::Comments;
{
  $Audio::Metadata::Flac::Block::Comments::VERSION = '0.16';
}
BEGIN {
  $Audio::Metadata::Flac::Block::Comments::VERSION = '0.15';
}

use strict;
use warnings;

use Any::Moose;


extends 'Audio::Metadata::Flac::Block';

has vendor   => ( isa => 'Str', is => 'rw', );
has comments => ( isa => 'HashRef', is => 'rw', default => sub { {} }, );


__PACKAGE__->meta->make_immutable;


sub type_code {
    ## Overriden.

    4;
}


sub BUILDARGS {
    ## Parses the block, setting properties.
    my $self = shift;
    my ($init_content) = @_;

    # Note that comments are in Vorbis format which uses little-endian byte order
    # as opposed to FLAC's big-endian.

    # Parse vendor string.
    my $vendor_str_size = unpack('V', $init_content);
    my $offset = 4 + $vendor_str_size;
    my %result = (
        _init_content => $init_content,
        vendor        => substr($init_content, 4, $vendor_str_size),
    );

    # Parse comment count.
    my $comment_count = unpack('V', substr($init_content, $offset));
    $offset += 4;

    # Parse comments.
    for (1 .. $comment_count) {
        my $comment_size = unpack('V', substr($init_content, $offset));
        $offset += 4;
        my ($key, $value) = split /=/, substr($init_content, $offset, $comment_size);
        $result{comments}{$key} = $value;
        $offset += $comment_size;
    }

    return \%result;
}


sub get_var {
    ## Returns value for the given var.
    my $self = shift;
    my ($var) = @_;

    return $self->comments->{$var};
}


sub set_var {
    ## Sets var to given value. 'undef' deletes the var.
    my $self = shift;
    my ($var, $value) = @_;

    if (defined $value) {
        $self->comments->{$var} = $value;
    }
    else {
        delete $self->comments->{$var};
    }
}


sub content_as_string {
    ## Overriden.
    my $self = shift;

    # Pack vendor string.
    my $content = pack('V', length($self->vendor)) . $self->vendor;

    # Add vars.
    my $vars = $self->comments;
    $content .= pack('V', scalar keys %$vars);
    while (my ($var, $value) = each %$vars) {
        my $var_str = $var . '=' . $value;
        $content .= pack('V', length($var_str)) . $var_str;
    }

    return $content;
}


sub as_string {
    ## Overriden.
    my $self = shift;

    return $self->_get_header . $self->content_as_string;
}


no Any::Moose;


1;


__END__

=head1 NAME

Audio::Metadata::Flac::Block::Comments - Representation of COMMENTS type block of FLAC metadata.

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
