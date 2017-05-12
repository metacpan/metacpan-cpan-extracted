package Data::CouchDB::Role::VersionedData;
use strict; use warnings;

our $VERSION = '0.14';

=head1 NAME

Data::CouchDB::Role::VersionedData

=head1 DESCRIPTION

Handles pulling in symbol-related data versioned by date.

=cut

use Net::SSL;
use JSON qw(to_json from_json);
use List::Util qw(min max);
use Moose::Role;
use Carp;
use URL::Encode qw(:all);
use Try::Tiny;

use Date::Utility;
use Data::CouchDB::Handler;

requires 'symbol', '_data_location', '_document_content';

=head1 ATTRIBUTES

=head2 for_date

The date for which we wish data

=cut

has for_date => (
    is      => 'ro',
    isa     => 'Maybe[Date::Utility]',
    default => undef,
);

=head2 current_document_id

=cut

has current_document_id => (
    is         => 'ro',
    isa        => 'Str',
    lazy_build => 1,
);

sub _build_current_document_id {
    my $self = shift;
    return $self->symbol;
}

=head2 document

The CouchDB document that this object is tied to.

=cut

has document => (
    is         => 'rw',
    lazy_build => 1,
);

sub _build_document {
    my $self = shift;

    my $document = $self->_couchdb->document($self->current_document_id);
    if ($self->for_date and $self->for_date->datetime_iso8601 lt $document->{date}) {
        my $params = {
            startkey   => [$self->symbol, $self->for_date->datetime_iso8601],
            endkey     => [$self->symbol],
            descending => 1,
            limit      => 1,
        };

        my $document_id = $self->_couchdb->view('by_date', $params)->[0];
        if ($document_id) {
            $document = $self->_couchdb->document($document_id);
        } else {
            $params = {
                startkey => [$self->symbol],
                endkey   => [$self->symbol, {}],
                limit    => 1,
            };

            $document_id = $self->_couchdb->view('by_date', $params)->[0];
            if ($document_id) {
                $document = $self->_couchdb->document($document_id);
            }

            $document //= {};
            $document->{date} = $self->for_date->datetime_iso8601;
        }
    }

    return $document;
}

has _couchdb => (
    is         => 'ro',
    isa        => 'Data::CouchDB',
    lazy_build => 1,
);

sub _build__couchdb {
    my $self = shift;

    my $handler = Data::CouchDB::Handler->new();
    if (exists $ENV{COUCHDB_DATABASES}) {
        $handler->couchdb_databases($ENV{COUCHDB_DATABASES});
    } else {
        $handler->couchdb_databases({
            $self->_data_location => $self->_data_location,
        });
    }

    return $handler->couchdb($self->_data_location);
}

=head2 add_to_history

Add the current live document to the searchable history

=cut

sub add_to_history {
    my ($self) = @_;

    # If its already a historical document hopefully its id will look like a uuid.
    if ($self->_looks_like_uuid($self->document->{_id})) {
        croak 'Saving historical document not permitted.';
    }

    delete $self->document->{_rev};
    my $historical_doc = $self->_couchdb->create_document();
    return $self->_couchdb->document($historical_doc, $self->document);
}

=head2 save

=cut

sub save {
    my $self = shift;

    if (not $self->_couchdb->document_present($self->current_document_id)) {
        $self->_couchdb->create_document($self->current_document_id);
    } else {
        $self->add_to_history;
    }

    my $new_document = $self->_document_content;
    $self->document($new_document);
    return $self->_couchdb->document($self->current_document_id, $new_document);
}

sub _looks_like_uuid {
    my ($self, $candidate) = @_;
    return ($candidate and $candidate =~ /^\w{32}$/);
}

1;
