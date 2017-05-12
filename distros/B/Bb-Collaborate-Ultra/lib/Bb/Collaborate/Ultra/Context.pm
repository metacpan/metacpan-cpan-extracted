package Bb::Collaborate::Ultra::Context;
use warnings; use strict;
use Mouse;
extends 'Bb::Collaborate::Ultra::DAO';
__PACKAGE__->resource('contexts');
__PACKAGE__->load_schema(<DATA>);

__PACKAGE__->query_params(
    name => 'Str',
    extId => 'Str',
    );

=head1 NAME

Bb::Collaborate::Ultra::Context - Session/recording context

=head1 DESCRIPTION

A Context entity allows for grouping or classification of sessions and associated recordings.

=head1 METHODS

This class supports the `get` and `post` methods as described in L<https://xx-csa.bbcollab.com/documentation#Context>.

=head1 BUGS AND LIMITATIONS



=cut
    
=head2 associate_session

    my $now = time();
    my $session = Bb::Collaborate::Ultra::Session->post($connection, {
	    name => 'My Session',
	    startTime => $now,
	    endTime   => $now + 1800,
	    },
	);
    my $context = Bb::Collaborate::Ultra::Context->find_or_create(
	    $connection, {
		extId => 'demo-sessions',
		name => 'Demo Sessions',
	    });
    $context->associate_session($session);

    # retrieve all sessions that have been associated with this context

    my @sessions = Bb::Collaborate::Ultra::Session->get($connection, {contextId => $context->id, limit => 5}, )

=cut

sub associate_session {
    my $self = shift;
    my $session = shift;

    die 'usage: $context->associate_session($session)'
	unless ref($self) && $session;
    my $session_id = $session->id;
    my $path = $self->path . '/sessions';
    my $json = $session->_freeze( { id => $session_id } );
    $self->connection->POST($path, $json );
}

# downloaded from https://xx-csa.bbcollab.com/documentation
1;
__DATA__
                {
  "type" : "object",
  "id" : "Context",
  "properties" : {
    "id" : {
      "type" : "string"
    },
    "title" : {
      "type" : "string"
    },
    "created" : {
      "type" : "string",
      "format" : "DATE_TIME"
    },
    "name" : {
      "type" : "string",
      "required" : true
    },
    "label" : {
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
