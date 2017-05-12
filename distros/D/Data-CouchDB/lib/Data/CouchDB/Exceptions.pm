package Data::CouchDB::Exceptions;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.14';

=head1 NAME

Data::CouchDB - CouchDB document management

=cut

use Exception::Class (

    'Data::CouchDB::Exception' => {
        fields => ['uri', 'error'],
        isa    => 'Exception::Class::Base'
    },

    'Data::CouchDB::ConnectionFailed' => {
        isa         => 'Data::CouchDB::Exception',
        description => 'Connection to couch db failed',
    },

    'Data::CouchDB::DBNotFound' => {
        isa         => 'Data::CouchDB::Exception',
        description => 'The DB you are looking for does not exist',
        fields      => ['uri', 'error', 'db'],
    },

    'Data::CouchDB::RetrieveFailed' => {
        isa         => 'Data::CouchDB::Exception',
        description => 'Document is not found in couch',
        fields      => ['db', 'uri', 'error', 'document'],
    },

    'Data::CouchDB::RevisionNotMatched' => {
        isa         => 'Data::CouchDB::Exception',
        description => 'Revision of document provided not match the one in couch',
        fields      => ['db', 'uri', 'error', 'document'],
    },

    'Data::CouchDB::UpdateFailed' => {
        isa         => 'Data::CouchDB::Exception',
        description => 'Revision of document provided not match the one in couch',
        fields      => ['db', 'uri', 'error', 'document'],
    },

    'Data::CouchDB::QueryFailed' => {
        isa         => 'Data::CouchDB::Exception',
        description => 'Revision of document provided not match the one in couch',
        fields      => ['db', 'uri', 'error', 'view'],
    },
);

sub full_message { my $self = shift; return 'Connection to db ' . $self->db . '@' . $self->uri . ' failed with error ' . $self->error; }

1;
