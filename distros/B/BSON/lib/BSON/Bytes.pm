use 5.010001;
use strict;
use warnings;

package BSON::Bytes;
# ABSTRACT: BSON type wrapper for binary byte strings

use version;
our $VERSION = 'v1.12.2';

use MIME::Base64 ();
use Tie::IxHash;

use Moo;

#pod =attr data
#pod
#pod A scalar, interpreted as bytes.  (I.e. "character" data should be encoded
#pod to bytes.)  It defaults to the empty string.
#pod
#pod =attr subtype
#pod
#pod A numeric BSON subtype between 0 and 255.  This defaults to 0 and generally
#pod should not be modified.  Subtypes 128 to 255 are "user-defined".
#pod
#pod =cut

has [qw/data subtype/] => (
    is      => 'ro',
);

use namespace::clean -except => 'meta';

sub BUILD {
    my ($self) = @_;
    $self->{data} = '' unless defined $self->{data};
    $self->{subtype} = 0 unless defined $self->{subtype};
}

#pod =method TO_JSON
#pod
#pod Returns Base64 encoded string equivalent to the data attribute.
#pod
#pod If the C<BSON_EXTJSON> option is true, it will instead be compatible with
#pod MongoDB's L<extended JSON|https://github.com/mongodb/specifications/blob/master/source/extended-json.rst>
#pod format, which represents it as a document as follows:
#pod
#pod     {"$binary" : { "base64": "<base64 data>", "subType" : "<type>"} }
#pod
#pod =cut

sub TO_JSON {
    return MIME::Base64::encode_base64($_[0]->{data}, "") unless $ENV{BSON_EXTJSON};

    my %data;
    tie( %data, 'Tie::IxHash' );
    $data{base64} = MIME::Base64::encode_base64($_[0]->{data}, "");
    $data{subType} = sprintf("%02x",$_[0]->{subtype});

    return {
        '$binary' => \%data,
    };
}

use overload (
    q{""}    => sub { $_[0]->{data} },
    fallback => 1,
);

# backwards compatibility alias
*type = \&subtype;

1;

=pod

=encoding UTF-8

=head1 NAME

BSON::Bytes - BSON type wrapper for binary byte strings

=head1 VERSION

version v1.12.2

=head1 SYNOPSIS

    use BSON::Types ':all';

    $bytes = bson_bytes( $bytestring );
    $bytes = bson_bytes( $bytestring, $subtype );

=head1 DESCRIPTION

This module provides a BSON type wrapper for binary data represented
as a string of bytes.

=head1 ATTRIBUTES

=head2 data

A scalar, interpreted as bytes.  (I.e. "character" data should be encoded
to bytes.)  It defaults to the empty string.

=head2 subtype

A numeric BSON subtype between 0 and 255.  This defaults to 0 and generally
should not be modified.  Subtypes 128 to 255 are "user-defined".

=head1 METHODS

=head2 TO_JSON

Returns Base64 encoded string equivalent to the data attribute.

If the C<BSON_EXTJSON> option is true, it will instead be compatible with
MongoDB's L<extended JSON|https://github.com/mongodb/specifications/blob/master/source/extended-json.rst>
format, which represents it as a document as follows:

    {"$binary" : { "base64": "<base64 data>", "subType" : "<type>"} }

=for Pod::Coverage BUILD type

=head1 OVERLOADING

The stringification operator (C<"">) is overloaded to return the binary data
and fallback overloading is enabled.

=head1 AUTHORS

=over 4

=item *

David Golden <david@mongodb.com>

=item *

Stefan G. <minimalist@lavabit.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Stefan G. and MongoDB, Inc.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut

__END__


# vim: set ts=4 sts=4 sw=4 et tw=75:
