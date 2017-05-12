package ArangoDB::Index::CapConstraint;
use strict;
use warnings;
use utf8;
use 5.008001;
use parent 'ArangoDB::Index';
use Class::Accessor::Lite ( ro => [qw/size/], );

1;
__END__

=pod

=head1 NAME

ArangoDB::Index::CapConstraint - An ArangoDB Cap Constraint

=head1 DESCRIPTION

Instance of ArangoDB cap constraint.

=head1 METHODS

=head2 new()

Constructor.

=head2 id()

Returns identifier of index.

=head2 type()

Returns type of index.
This method will return 'cap'.

=head2 collection_id()

Returns identifier of the index.

=head2 size()

Restriction size of collection.

=head2 drop()

Drop the index.

=head1 AUTHOR

Hideaki Ohno E<lt>hide.o.j55 {at} gmail.comE<gt>

=cut
