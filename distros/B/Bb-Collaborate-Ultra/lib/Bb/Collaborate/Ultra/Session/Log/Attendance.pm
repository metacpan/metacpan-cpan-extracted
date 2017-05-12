package Bb::Collaborate::Ultra::Session::Log::Attendance;
use warnings; use strict;
use Mouse;
extends 'Bb::Collaborate::Ultra::DAO';
use Mouse::Util::TypeConstraints;

=head1 NAME

Bb::Collaborate::Ultra::Session::Log::Attendance

=head1 DESCRIPTION

Logs an individual attendence.

=head1 METHODS

See L<https://xx-csa.bbcollab.com/documentation#Attendee-collection>

=cut
    

coerce __PACKAGE__, from 'HashRef' => via {
    __PACKAGE__->new( $_ )
};
 
__PACKAGE__->load_schema(<DATA>);
# downloaded from https://xx-csa.bbcollab.com/documentation
1;
__DATA__
{
      "type" : "object",
      "id" : "urn:jsonschema:com:blackboard:collaborate:csl:core:dto:AttendeeLog",
      "properties" : {
	  "duration" : {
	  "type" : "integer"
	  },
	      "joined" : {
	  "type" : "string",
	  "format" : "DATE_TIME"
	  },
	      "left" : {
	  "type" : "string",
	  "format" : "DATE_TIME"
	  }
      }
    }
