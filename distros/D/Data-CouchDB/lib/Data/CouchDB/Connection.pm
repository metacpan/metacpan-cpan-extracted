package Data::CouchDB::Connection;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.14';

=head1 NAME

Data::CouchDB - CouchDB document management

=cut

=head1 NAME

Data::CouchDB::Connection

=head1 SYNOPSYS

    my $couch_connection = Data::CouchDB::Connection->new(
        host   => 'localhost',
        port   => 5432,
        protocol => 'http://',
        couch => 'testdb',
    );

=head1 DESCRIPTION

This class represents a couchdb connection.

=head1 ATTRIBUTES

=cut

use Moose;
use MooseX::StrictConstructor;
use namespace::autoclean;

use CouchDB::Client;
use Net::SSL;
use LWP::UserAgent;
use HTTP::Request;
use HTTP::Headers;
use Try::Tiny;
use IO::Socket::SSL qw( SSL_VERIFY_NONE );
use Data::CouchDB::Exceptions;

=head2 host

name of the host to connect to.

=cut

has 'host' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

=head2 port

name of the port to connect to.

=cut

has 'port' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

=head2 db

db with which to operate.

=cut

has db => (
    is      => 'ro',
    isa     => 'Str',
    default => 'db',
);

=head2 protocol

protcol with which to connect.

Can be,
    'http://' or 'https://'

=cut

has 'protocol' => (
    is         => 'ro',
    isa        => 'Str',
    lazy_build => 1,
);

=head2 couchdb

password for "couchdb" user

=cut

has 'couchdb' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'TESTPASS'
);

=head2 design_doc

Location inside the db where the design document is present.

=cut

has 'design_doc' => (
    is      => 'ro',
    default => '_design/docs'
);

=head2 uri

The uri with which we connect to.

=cut

has 'uri' => (
    is         => 'ro',
    isa        => 'Str',
    lazy_build => 1,
);

=head2 log_uri

The uri we use for throwing exceptions.

=cut

has 'log_uri' => (
    is         => 'ro',
    isa        => 'Str',
    lazy_build => 1,
);

=head2 ua

Optionally passed ua(user_agent). If not passed the couchdb's default ua is used.

=cut

has 'ua' => (
    is         => 'ro',
    lazy_build => 1,
);

=head1 METHODS

=head2 document

Get or set a couch document.

Usage,
    To get a document
        $couchdb->document($db, $doc_id);

    To set a document
        $couchdb->document($db, $doc_id, $data);

        $data is a HashRef

=cut

sub document {
    my $self      = shift;
    my $doc       = shift;
    my $data      = shift;
    my $ex_params = shift || {};

    return unless ($doc);
    my $couch_doc = $self->_doc($doc);
    try { $couch_doc->retrieve; }
    catch {
        Data::CouchDB::RetrieveFailed->throw(
            db       => $self->db,
            uri      => $self->log_uri,
            document => $doc,
            error    => $_,
        );
    };

    if ($data) {
        if (exists $data->{_rev}) {
            if ($data->{_rev} ne $couch_doc->rev) {
                Data::CouchDB::RevisionNotMatched->throw(
                    uri      => $self->log_uri,
                    db       => $self->db,
                    document => $doc,
                    error    => "CouchDB Revision mismatch " . $data->{_rev} . '!=' . $couch_doc->rev
                );
            }
            delete $data->{_rev};
        }

        delete $data->{_id} if (exists $data->{_id});

        try {
            $couch_doc->data($data);
            $couch_doc->update;
        }
        catch {
            Data::CouchDB::UpdateFailed->throw(
                uri      => $self->log_uri,
                db       => $self->db,
                document => $doc,
                error    => $_,
            );
        };

    }

    $data         = $couch_doc->data;
    $data->{_rev} = $couch_doc->rev;
    $data->{_id}  = $couch_doc->id;

    return $data;
}

=head2 view

Query a couchdb view

Usage,
    Without Parameters
        $couchdb->view($db, $viewname);

    With Parameters
        $couchdb->view($db, $viewname, $parameters);

        $parameters is a HashRef


=cut

sub view {
    my $self      = shift;
    my $view      = shift;
    my $params    = shift;
    my $ex_params = shift || {};

    my $design_doc = $ex_params->{design_doc} || $self->design_doc;

    return unless ($view);

    my $couch_design_doc = $self->_retrieved_design_doc;
    my $result;
    try { $result = $couch_design_doc->queryView($view, %$params); }
    catch {
        Data::CouchDB::QueryFailed->throw(
            db    => $self->db,
            uri   => $self->log_uri,
            view  => $view,
            error => $_,
        );
    };

    my $documents = [];
    foreach my $row (@{$result->{rows}}) {
        if ($row->{id}) {
            push @{$documents}, $row->{id};
        } else {
            push @{$documents}, $row;
        }
    }

    return $documents;
}

=head2 can_connect

Confirms that you can connect to this couchdb

Usage,
    if($couchdb->can_connect) {
        ...
    }

Returns,
    1     - can read
    undef - otherwise
=cut

sub can_connect {
    my $self = shift;

    my $client = CouchDB::Client->new(uri => $self->uri);
    return $client->testConnection;
}

=head2 create_or_update_view

Creates a CouchDB view.

=cut

sub create_or_update_view {
    my $self     = shift;
    my $new_view = shift;

    my $doc = $self->_design_doc;
    my $design_doc;
    try { $doc->retrieve; $design_doc = $doc->data; };

    # possibly new view
    unless ($design_doc) {
        $doc->create;
        $design_doc = {};
        $design_doc->{views} = {};
    }

    $design_doc->{views} = {%{$design_doc->{views}}, %$new_view};
    try {
        $doc->data($design_doc);
        $doc->update;
    }
    catch {
        Data::CouchDB::UpdateFailed->throw(
            uri      => $self->log_uri,
            db       => $self->db,
            document => $self->design_doc,
            error    => $_,
        );
    };

    # Recreate design doc since we updated it.
    $self->_design_doc($self->_build__design_doc);
    $self->_retrieved_design_doc($self->_build__retrieved_design_doc);

    return 1;
}

=head2 create_document

Creates a couch document

Usage,
    With known doc_id
        my $doc_id = $couchdb->create_document($db, $doc_id);

    Without known doc_id or with rev
        my $doc_id = $couchdb->create_document($db);

=cut

sub create_document {
    my $self      = shift;
    my $doc       = shift;
    my $ex_params = shift || {};

    my $couch_doc = $self->_doc($doc);

    try { $couch_doc->create; }
    catch {
        Data::CouchDB::Exception->throw(
            uri     => $self->log_uri,
            error   => $_,
            message => "Creating " . (($doc) ? $doc : "new") . " in " . $self->db . " failed: $_",
        );
    };

    return $couch_doc->id;
}

=head2 delete_document

Deletes a couch document

Usage,
    $couchdb->delete_document($db, $doc_id);


=cut

sub delete_document {
    my $self      = shift;
    my $doc       = shift;
    my $ex_params = shift || {};

    my $couch_doc = $self->_doc($doc);

    try {
        $couch_doc->retrieve;
        $couch_doc->delete;
    }
    catch {
        Data::CouchDB::Exception->throw(
            uri     => $self->log_uri,
            error   => $_,
            message => "Deleting $doc from " . $self->db . " failed",
        );
    };

    return 1;
}

=head2 create_database

Creates a CouchDB Database.

Usage,
    $couchdb->create_database($db);


=cut

sub create_database {
    my $self = shift;
    return $self->_db->create;
}

sub database_exists {
    my $self = shift;
    return $self->_couchdb_client->dbExists($self->db);
}

sub _doc {
    my $self = shift;
    my $doc  = shift;

    return $self->_db->newDoc($doc);
}

has _couchdb_client => (
    is         => 'ro',
    isa        => 'CouchDB::Client',
    lazy_build => 1,
);

has _db => (
    is         => 'ro',
    isa        => 'CouchDB::Client::DB',
    lazy_build => 1,
);

has '_design_doc' => (
    is         => 'rw',
    lazy_build => 1,
);

has '_retrieved_design_doc' => (
    is         => 'rw',
    lazy_build => 1,
);

sub _build__couchdb_client {
    my $self = shift;

    my $params = {};
    $params->{uri} = $self->uri;
    $params->{ua} = $self->ua if ($self->ua);

    my $client = CouchDB::Client->new($params);
    unless ($client->testConnection) {
        Data::CouchDB::ConnectionFailed->throw(
            uri   => $self->log_uri,
            error => 'Connection to  ' . $self->log_uri . ' failed',
        );
    }

    return $client;
}

sub _build__db {
    my $self = shift;
    return $self->_couchdb_client->newDB($self->db);
}

sub _build__design_doc {
    my $self = shift;

    return $self->_db->newDesignDoc($self->design_doc);
}

sub _build__retrieved_design_doc {
    my $self = shift;

    my $design_doc = $self->_design_doc;
    try { $design_doc->retrieve; }
    catch {
        Data::CouchDB::RetrieveFailed->throw(
            db       => $self->db,
            uri      => $self->log_uri,
            document => $self->design_doc,
            error    => $_,
        );
    };

    return $self->_design_doc;
}

sub _build_uri {
    my $self     = shift;
    my $protocol = $self->protocol;
    my $url      = $protocol;

    # If couchdb is not set then it has no password
    if ($self->port ne 5984 and $self->couchdb) {
        $url .= 'couchdb:' . $self->couchdb . '@';
    }

    $url .= $self->host . ':' . $self->port . '/';
    return $url;
}

sub _build_log_uri {
    my $self = shift;
    my $uri  = $self->protocol;

    return $self->protocol . $self->host . ':' . $self->port . '/';
}

sub _build_protocol {
    my $self = shift;
    my $port = $self->port;
    my $protocol;

    if ($port eq 6984) {
        $protocol = 'https://';
    } elsif ($port eq 5984) {
        $protocol = 'http://';
    }

    return $protocol;
}

sub _build_ua {
    my $self = shift;

    my $ua = LWP::UserAgent->new();
    $ua->ssl_opts(
        verify_hostname => 0,
        SSL_verify_mode => SSL_VERIFY_NONE
    );

    return $ua;
}

__PACKAGE__->meta->make_immutable;

1;

