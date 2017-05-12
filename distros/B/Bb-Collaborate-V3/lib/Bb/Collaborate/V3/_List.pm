package Bb::Collaborate::V3::_List;
use warnings; use strict;

use Mouse;
use Mouse::Util::TypeConstraints;

use Elive::DAO::Array;
extends 'Elive::DAO::Array';

use Scalar::Util;

=head1 NAME

Bb::Collaborate::V3::_List - Base class for lists.

=head1 DESCRIPTION

Used as a base class for chair-persons, participants, courses and session attendees.

=cut

=head1 METHODS

=cut

=head2 add 

    $list->add('111111', '222222');

Add additional elements

=cut

coerce 'Bb::Collaborate::V3::_List' => from 'ArrayRef'
          => via {
	      my @items = grep {$_ ne ''} map {split(',')} @$_;
	      Bb::Collaborate::V3::_List->new(\@items);
};

coerce 'Bb::Collaborate::V3::_List' => from 'Str'
          => via {
	      my @items = grep {$_ ne ''} split(',');

	      Bb::Collaborate::V3::_List->new(\@items);
          };

=head2 stringify

Serialises array members by joining their string values with ','. Typically
used to pack SOAP data, E.G. Session chair persons.

=cut

sub stringify {
    my $self = shift;
    my $arr  = shift || $self;
    my $type = shift || $self->element_class;

    $arr = [sort split(',', $arr)]
	if defined $arr && !Scalar::Util::reftype($arr);

    return join(',', sort map {Elive::Util::string($_, $type)} @$arr)
}

1;
