package Bb::Collaborate::V3::Session::Attendees;
use warnings; use strict;

use Mouse;
use Mouse::Util::TypeConstraints;

use Scalar::Util;

extends 'Bb::Collaborate::V3::_List';

use Bb::Collaborate::V3::Session::Attendee;

__PACKAGE__->element_class('Bb::Collaborate::V3::SessionAttendence::Attendee');

=head1 NAME

Bb::Collaborate::V3::Session::Attendees - Container class for a list of session attendees

=cut

=head1 METHODS

=cut

coerce 'Bb::Collaborate::V3::Session::Attendees' => from 'ArrayRef'
          => via {
	      my @attendees
		  = (map {Scalar::Util::blessed($_)
			      ? $_
			      : Bb::Collaborate::V3::Session::Attendee->new($_)
		     } @$_);

	      Bb::Collaborate::V3::Session::Attendees->new(\@attendees);
};

coerce 'Bb::Collaborate::V3::Session::Attendees' => from 'HashRef'
          => via {
	      my $attendee = Scalar::Util::blessed($_)
		  ? $_
		  : Bb::Collaborate::V3::Session::Attendee->new($_);

	      Bb::Collaborate::V3::Session::Attendees->new([ $attendee ]);
};

1;
