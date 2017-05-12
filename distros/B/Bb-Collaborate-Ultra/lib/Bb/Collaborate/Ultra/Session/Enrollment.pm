package Bb::Collaborate::Ultra::Session::Enrollment;
use warnings; use strict;
use Mouse;
extends 'Bb::Collaborate::Ultra::DAO';
__PACKAGE__->resource('enrollments');
__PACKAGE__->load_schema(<DATA>);

=head1 NAME

Bb::Collaborate::Ultra::Session::Enrollment - Session enrollments

=head2 METHODS

See L<https://xx-csa.bbcollab.com/documentation#Session::Enrollment>

=cut

=head2 enrol

Enrols a given user a session

=cut

sub enrol {
    my $self = shift;
    my $session = shift || $self->parent
	|| die "no sesson to enrol in";
    my $connection = shift
	    || $self->connection
	    || $session->connection
	or die "not connected";
    my $path = $self->path(parent => $session);
    my $enrolment = $self->post($connection, $self->_raw_data, path => $path);
}

# downloaded from https://xx-csa.bbcollab.com/documentation
1;
__DATA__
               {
  "type" : "object",
  "id" : "Session::Enrollment",
  "properties" : {
    "id" : {
      "type" : "string"
    },
    "userId" : {
      "type" : "string"
    },
    "launchingRole" : {
      "type" : "string",
      "enum" : [ "participant", "moderator", "presenter" ]
    },
    "permanentUrl" : {
      "type" : "string"
    },
    "editingPermission" : {
      "type" : "string",
      "enum" : [ "reader", "writer" ]
    }
  }
}
