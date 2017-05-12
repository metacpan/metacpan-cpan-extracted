package Bb::Collaborate::Ultra::Recording;
use warnings; use strict;
use Mouse;
extends 'Bb::Collaborate::Ultra::DAO';
__PACKAGE__->resource('recordings');
__PACKAGE__->load_schema(<DATA>);

__PACKAGE__->query_params(
    name => 'Str',
    contextId => 'Str',
    startTime => 'Date',
    endTime => 'Date'
    );

=head1 NAME

Bb::Collaborate::Ultra::Recording - Session Recordings

=head1 METHODS

This class supports the `get` and `delete` methods as described in L<https://xx-csa.bbcollab.com/documentation#Recording>.

=cut
    
=head2 url

Returns a play-back URL for the recording

=cut

sub url {
    my $self = shift;
    my $connection = shift || $self->connection;
    my $path = $self->path.'/url';
    my $response = $connection->GET($path);
    $response->{url};
}

# downloaded from https://xx-csa.bbcollab.com/documentation
1;
__DATA__
                {
  "type" : "object",
  "id" : "Recording",
  "properties" : {
    "sessionStartTime" : {
      "type" : "string",
      "format" : "DATE_TIME"
    },
    "ownerId" : {
      "type" : "string"
    },
    "mediaName" : {
      "type" : "string"
    },
    "restricted" : {
      "type" : "boolean"
    },
    "endTime" : {
      "type" : "string",
      "format" : "DATE_TIME"
    },
    "editingPermission" : {
      "type" : "string",
      "enum" : [ "reader", "writer" ]
    },
    "modified" : {
      "type" : "string",
      "format" : "DATE_TIME"
    },
    "startTime" : {
      "type" : "string",
      "format" : "DATE_TIME"
    },
    "id" : {
      "type" : "string"
    },
    "canDownload" : {
      "type" : "boolean"
    },
    "duration" : {
      "type" : "integer"
    },
    "sessionName" : {
      "type" : "string"
    },
    "created" : {
      "type" : "string",
      "format" : "DATE_TIME"
    },
    "name" : {
      "type" : "string"
    }
  }
}
