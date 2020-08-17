use 5.010001;
use strict;
use warnings;

package BSON::ObjectId;
# ABSTRACT: Legacy BSON type wrapper for Object IDs (DEPRECATED)

use version;
our $VERSION = 'v1.12.2';

use Carp;

use BSON::OID;
our @ISA = qw/BSON::OID/;

sub new {
    my ( $class, $value ) = @_;
    my $self = bless {}, $class;
    if ( $value ) {
        $self->value( $value );
    }
    else {
        $self->{oid} = BSON::OID::_packed_oid();
    }
    return $self;
}

sub value {
    my ( $self, $new_value ) = @_;
    if ( defined $new_value ) {
        if ( length($new_value) == 12 ) {
            $self->{oid} = $new_value;
        }
        elsif ( length($new_value) == 24 && $self->is_legal($new_value) ) {
            $self->{oid} = pack("H*", $new_value);
        }
        else {
            croak("BSON::ObjectId must be a 12 byte or 24 char hex value");
        }
    }
    return $self->{oid};
}

sub is_legal {
    $_[1] =~ /^[0-9a-f]{24}$/i;
}

sub to_s { $_[0]->to_string }

1;

=pod

=encoding UTF-8

=head1 NAME

BSON::ObjectId - Legacy BSON type wrapper for Object IDs (DEPRECATED)

=head1 VERSION

version v1.12.2

=head1 DESCRIPTION

This module has been deprecated as it was not compatible with
the official MongoDB BSON implementation on CPAN.

You are strongly encouraged to use L<BSON::OID> instead.

=for Pod::Coverage to_s is_legal new value

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
