package Bb::Collaborate::Ultra::LaunchContext;
use warnings; use strict;
use Mouse;
extends 'Bb::Collaborate::Ultra::DAO';
use Bb::Collaborate::Ultra::User;
has 'user' => (isa => 'Bb::Collaborate::Ultra::User', is => 'rw', coerce => 1);

=head1 NAME

Bb::Collaborate::Ultra::LaunchContext - Session Launch Context

=head1 DESCRIPTION

This class is used to construct details for joining a session,
including user identification and permissions.

    my $user = Bb::Collaborate::Ultra::User->new({
	extId => 'testLaunchUser',
	displayName => 'David Warring',
	email => 'david.warring@gmail.com',
	firstName => 'David',
	lastName => 'Warring',
    });

    my $launch_context =  Bb::Collaborate::Ultra::LaunchContext->new({ launchingRole => 'moderator',
	 editingPermission => 'writer',
	 user => $user,
	 });

=head1 METHODS

See L<https://xx-csa.bbcollab.com/documentation#Launch-context>.

=cut
    
=head2 join_session

    my $join_url = $launch_context->join_session($session);

Obtain a url to join a particular session.

=cut


sub join_session {
    my $self = shift;
    my $session = shift;
    my $connection = shift || $session->connection
	or die "not connected";
    my $session_path = $session->path.'/url';
    my $data = $self->_freeze;
    my $response = $connection->POST($session_path, $data);
    my $msg = $response;
    $msg->{url};
}

__PACKAGE__->load_schema(<DATA>);
1;
# downloaded from https://xx-csa.bbcollab.com/documentation
__DATA__
               {
  "type" : "object",
  "id" : "UserLaunchContext",
  "properties" : {
    "returnUrl" : {
      "type" : "string"
    },
    "reconnectUrl" : {
      "type" : "string"
    },
    "locale" : {
      "type" : "string"
    },
    "launchingRole" : {
      "type" : "string",
      "enum" : [ "participant", "moderator", "presenter" ]
    },
    "editingPermission" : {
      "type" : "string",
      "enum" : [ "reader", "writer" ]
    },
    "originDomain" : {
      "type" : "string"
    },
    "user" : {
      "type" : "object",
      "id" : "User",
      "properties" : {
        "id" : {
          "type" : "string"
        },
        "lastName" : {
          "type" : "string"
        },
        "created" : {
          "type" : "string",
          "format" : "DATE_TIME"
        },
        "passwordModified" : {
          "type" : "string",
          "format" : "DATE_TIME"
        },
        "email" : {
          "type" : "string"
        },
        "ltiLaunchDetails" : {
          "type" : "object",
          "additionalProperties" : {
            "type" : "any"
          }
        },
        "avatarUrl" : {
          "type" : "string"
        },
        "userName" : {
          "type" : "string"
        },
        "displayName" : {
          "type" : "string"
        },
        "firstName" : {
          "type" : "string"
        },
        "extId" : {
          "type" : "string"
        },
        "modified" : {
          "type" : "string",
          "format" : "DATE_TIME"
        }
      }
    }
  }
}
