package Bb::Collaborate::Ultra::Session::Log::Attendee;
use warnings; use strict;
use Mouse;
extends 'Bb::Collaborate::Ultra::DAO';
use Mouse::Util::TypeConstraints;
use Bb::Collaborate::Ultra::Session::Log::Attendance;

=head1 NAME

Bb::Collaborate::Ultra::Session::Attendee

=head1 DESCRIPTION

Logs Session attendances for an attendee.

=head1 METHODS

See L<https://xx-csa.bbcollab.com/documentation#Attendee-collection>

=cut

subtype 'ArrayOfAttendences',
    as 'ArrayRef[Bb::Collaborate::Ultra::Session::Log::Attendance]';

coerce 'ArrayOfAttendences',
    from 'ArrayRef[HashRef]',
    via { [ map {Bb::Collaborate::Ultra::Session::Log::Attendance->new($_)} (@$_) ] };

has 'attendance' => (isa => 'ArrayOfAttendences', is => 'rw', coerce => 1);

sub _thaw {
    my $self = shift;
    my $data = shift;
    my $thawed = $self->SUPER::_thaw($data, @_);
    my $attendance = $data->{attendance};
    $thawed->{attendance} = [ map { Bb::Collaborate::Ultra::Session::Log::Attendance->_thaw($_) } (@$attendance) ]
	if $attendance;
    $thawed;
}

coerce __PACKAGE__, from 'HashRef' => via {
    __PACKAGE__->new( $_ )
};
 
__PACKAGE__->load_schema(<DATA>);
# downloaded from https://xx-csa.bbcollab.com/documentation
1;
__DATA__
{
	  "type" : "object",
	  "id" : "urn:jsonschema:com:blackboard:collaborate:csl:core:dto:Attendee",
	  "properties" : {
	    "externalUserId" : {
            "type" : "string"
	    },
	    "userId" : {
            "type" : "string"
	    },
		"role" : {
            "type" : "string"
	    },
		"displayName" : {
            "type" : "string"
	    }
        }
}
