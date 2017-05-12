package ArangoDB::Index::Geo;
use strict;
use warnings;
use utf8;
use 5.008001;
use parent 'ArangoDB::Index';
use Class::Accessor::Lite ( ro => [qw/fields geoJson constraint/], );

1;
__END__

=pod

=head1 NAME

ArangoDB::Index::Geo - An ArangoDB Geo Index

=head1 DESCRIPTION

Instance of ArangoDB geo index.

=head1 METHODS

=head2 new()

Constructor.

=head2 id()

Returns identifier of index.

=head2 type()

Returns type of index.
This method will return 'geo1' or 'geo2'.

=over 4

=item geo1

A geo index with one field. The value of the field is a list of two double values(latitude and longitude).

=item geo2

A geo index with two fields(latitude and longitude).

=back

=head2 collection_id()

Returns identifier of the index.

=head2 fields()

List of attribure paths.

=head2 geoJson()

If it is true, This geo-spatial index is using geojson format.

=head2 constraint()

If it is true, this index is geo-spatial constraint.

=head2 drop()

Drop the index.

=head1 AUTHOR

Hideaki Ohno E<lt>hide.o.j55 {at} gmail.comE<gt>

=cut
