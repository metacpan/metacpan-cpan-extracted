package AnyMongo::BSON::OID;
BEGIN {
  $AnyMongo::BSON::OID::VERSION = '0.03';
}
# ABSTRACT: A Mongo ObjectId
use strict;
use warnings;
# use namespace::autoclean;
use AnyMongo;
use Any::Moose;


has value => (
    is      => 'ro',
    isa     => 'Str',
    required => 1,
    builder => 'build_value',
);

sub BUILDARGS {
    my $class = shift;
    return $class->SUPER::BUILDARGS(flibble => @_) if @_ % 2;
    return $class->SUPER::BUILDARGS(@_);
}

sub build_value {
    my ($self, $str) = @_;
    $str = '' unless defined $str;

    _build_value($self, $str);
}


sub to_string {
    my ($self) = @_;
    $self->value;
}



sub get_time {
    my ($self) = @_;

    my $ts = 0;
    for (my $i = 0; $i<4; $i++) {
        $ts = ($ts * 256) + hex(substr($self->value, $i*2, 2));
    }
    return $ts;
}


sub TO_JSON {
    my ($self) = @_;
    return {'$oid' => $self->value};
}

use overload
    '""' => \&to_string,
    'fallback' => 1;

no Any::Moose;

# __PACKAGE__->meta->make_immutable (inline_destructor => 0);
__PACKAGE__->meta->make_immutable;

1;



=pod

=head1 NAME

AnyMongo::BSON::OID - A Mongo ObjectId

=head1 VERSION

version 0.03

=head1 SYNOPSIS

=head1 SYNOPSIS

If no C<_id> field is provided when a document is inserted into the database, an
C<_id> field will be added with a new C<MongoDB::OID> as its value.

    my $id = $collection->insert({'name' => 'Alice', age => 20});

C<$id> will be a C<MongoDB::OID> that can be used to retreive or update the
saved document:

    $collection->update({_id => $id}, {'age' => {'$inc' => 1}});
    # now Alice is 21

To create a copy of an existing OID, you must set the value attribute in the
constructor.  For example:

    my $id1 = MongoDB::OID->new;
    my $id2 = MongoDB::OID->new(value => $id1->value);

Now C<$id1> and C<$id2> will have the same value.

Warning: at the moment, OID generation is not thread safe.

=head1 DESCRIPTION

=head1 SEE ALSO

Core documentation on object ids: L<http://dochub.mongodb.org/core/objectids>.

=head1 ATTRIBUTES

=head2 value

The OID value. A random value will be generated if none exists already.
It is a 24-character hexidecimal string (12 bytes).  

Its string representation is the 24-character string.

=head1 METHODS

=head2 to_string

    my $hex = $oid->to_string;

Gets the value of this OID as a 24-digit hexidecimal string.

=head2 get_time

    my $date = DateTime->from_epoch(epoch => $id->get_time);

Each OID contains a 4 bytes timestamp from when it was created.  This method
extracts the timestamp.  

=head2 TO_JSON

    my $json = JSON->new;
    $json->allow_blessed;
    $json->convert_blessed;

    $json->encode(MongoDB::OID->new);

Returns a JSON string for this OID.  This is compatible with the strict JSON
representation used by MongoDB, that is, an OID with the value 
"012345678901234567890123" will be represented as 
C<{"$oid" : "012345678901234567890123"}>.

=head1 NAME

AnyMongo::ObjectId 

=head1 AUTHOR

=head1 COPYRIGHT

=head1 AUTHORS

=over 4

=item *

Pan Fan(nightsailer) <nightsailer at gmail.com>

=item *

Kristina Chodorow <kristina at 10gen.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Pan Fan(nightsailer).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__


