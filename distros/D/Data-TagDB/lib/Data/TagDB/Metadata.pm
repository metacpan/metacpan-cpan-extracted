# Copyright (c) 2024 Löwenfelsen UG (haftungsbeschränkt)
# Copyright (c) 2024 Philipp Schafft

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: Work with Tag databases

package Data::TagDB::Metadata;

use v5.10;
use strict;
use warnings;

use parent 'Data::TagDB::Link';

use Carp;

our $VERSION = v0.04;



sub type {
    my ($self) = @_;
    return $self->{type};
}

sub encoding {
    my ($self) = @_;
    return $self->{encoding};
}

sub type_evaluated {
    my ($self) = @_;
    return $self->{type_evaluated} //= ($self->type // $self->db->_default_type($self->relation));
}

sub encoding_evaluated {
    my ($self) = @_;
    return $self->{encoding_evaluated} //= ($self->encoding // $self->db->_default_encoding($self->type_evaluated));
}


sub data_raw {
    my ($self) = @_;
    return $self->{data_raw};
}


sub data {
    my ($self) = @_;
    if (exists $self->{data}) {
        return $self->{data};
    } else {
        eval {
            $self->{data} = $self->db->_get_decoder($self)->($self);
        };
        croak 'Cannot decode' unless exists $self->{data};
        return $self->{data};
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::TagDB::Metadata - Work with Tag databases

=head1 VERSION

version v0.04

=head1 SYNOPSIS

    use Data::TagDB;

Package of Metadata. Inherits from L<Data::TagDB::Link>.

=head1 METHODS

=head2 type, encoding

    my Data::TagDB::Tag $db = $link->type;
    my Data::TagDB::Tag $db = $link->encoding;

Returns the corresponding type, or encoding. Returns undef if not set.

=head2 data_raw

    my $raw = $link->data_raw;

Returns the raw data of the metadata.

=head2 data

    my $data = $link->data;

Returns the data in what is considered the most native form for Perl.
E.g. URIs are returned in with package L<URI>.

This method requires a decoder to be installed for the given type and encoding.

=head1 AUTHOR

Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024 by Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
