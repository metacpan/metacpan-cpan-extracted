package ArangoDB2::Document;

use strict;
use warnings;

use base qw(
    ArangoDB2::Base
);

use Data::Dumper;
use JSON::XS;

my $JSON = JSON::XS->new->utf8;



# create
#
# POST /_api/document
#
# Query Parameters
#
# collection: The collection name.
# createCollection: If this parameter has a value of true or yes, then the collection is created if it does not yet exist. Other values will be ignored so the collection must be present for the operation to succeed.
#
# return self on success, undef on failure
sub create
{
    my($self, $data, $args) = @_;
    # require data
    die "Invlalid args"
        unless ref $data eq 'HASH';
    # process args
    $args = $self->_build_args($args, ['createCollection','waitForSync']);
    # set collection name as query param
    $args->{collection} = $self->collection->name;
    # make request
    my $res = $self->arango->http->post(
        $self->api_path($self->_class),
        $args,
        $JSON->encode($data),
    ) or return;
    # copy response data to instance
    $self->_build_self($res, []);
    # set data pointer to passed in doc, which will
    # be updated by future object ops
    $self->{data} = $data;
    # register
    my $register = $self->_register;
    $self->collection->$register->{$self->name} = $self;

    return $self;
}

# createCollection
#
# get/set createCollection
sub createCollection { shift->_get_set_bool('createCollection', @_) }

# delete
#
# DELETE /_api/document/{document-handle}
sub delete
{
    my($self, $args) = @_;
    # process args
    $args = $self->_build_args($args, ['policy', 'rev', 'waitForSync']);
    # make request
    my $res = $self->arango->http->delete(
        $self->api_path($self->_class, $self->collection->name, $self->name),
        $args,
    ) or return;
    # empty data
    if (my $data = $self->data) {
        %$data = ();
    }
    # unregister
    my $register = $self->_register;
    delete $self->collection->$register->{$self->name};

    return $res;
}

# edges
#
# GET /_api/edges/{collection-id}
#
# even though this is under the edge API it is the edges for a document
# so it makes more since for this to be a method on the document that the
# edges are being retrieved for.
#
# the edges method must be called with the edge collection that the edges
# are being retrieved from.
sub edges
{
    my($self, $collection, $args) = @_;
    # set default args
    $args ||= {};
    # require valid args
    die 'Invalid Args'
        unless ref $args eq 'HASH';
    # get the edges from this document
    $args->{vertex} = join('/', $self->collection->name, $self->name);

    return $self->arango->http->get(
        $self->api_path('edges', $collection->name),
        $args,
    );
}

# get
#
# GET /_api/document/{document-handle}
sub get
{
    my($self) = @_;
    # make request
    my $res = $self->arango->http->get(
        $self->api_path($self->_class, $self->collection->name, $self->name),
    ) or return;
    # copy response data to instance
    $self->_build_self($res, []);
    # if data is defined already then empty and copy data from response
    if (my $data = $self->data) {
        %$data = ();
        $data->{$_} = $res->{$_} for keys %$res;
    }
    # otherwise use res for data
    else {
        $self->data($res);
    }
    # register object
    my $register = $self->_register;
    $self->collection->$register->{$self->name} = $self;

    return $res;
}

# head
#
# HEAD /_api/document/{document-handle}
sub head
{
    my($self) = @_;

    my $res = $self->arango->http->head(
        $self->api_path($self->_class, $self->collection->name, $self->name),
    );

    return $res;
}

# keepNull
#
# get/set keepNull
sub keepNull { shift->_get_set_bool('keepNull', @_) }

# list
#
# GET /_api/document
sub list
{
    my($self, $args) = @_;
    # process args
    $args = $self->_build_args($args, ['type']);
    $args->{collection} = $self->collection->name;
    # make request
    return $self->arango->http->get(
        $self->api_path($self->_class),
        $args
    );
}

# update
#
# PATCH /_api/document/{document-handle}
sub update
{
    my($self, $data, $args) = @_;
    # process args
    $args = $self->_build_args($args, ['keepNull', 'policy', 'waitForSync']);
    # make request
    my $res = $self->arango->http->patch(
        $self->api_path($self->_class, $self->collection->name, $self->name),
        $args,
        $JSON->encode($data),
    ) or return;
    # copy response data to instance
    $self->_build_self($res, []);
    # if data is defined then copy patched data
    if (my $orig_data = $self->data) {
        $orig_data->{$_} = $data->{$_} for keys %$data;
    }
    # otherwise use passed data
    else {
        $self->data($data);
    }
    # register object
    my $register = $self->_register;
    $self->collection->$register->{$self->name} = $self;

    return $self;
}

# policy
#
# get/set policy
sub policy { shift->_get_set('policy', @_) }

# replace
#
# PUT /_api/document/{document-handle}
sub replace
{
    my($self, $data, $args) = @_;
    # process args
    $args = $self->_build_args($args, ['policy', 'waitForSync']);
    # make request
    my $res = $self->arango->http->put(
        $self->api_path($self->_class, $self->collection->name, $self->name),
        $args,
        $JSON->encode($data),
    ) or return;
    # copy response data to instance
    $self->_build_self($res, []);
    # if data is defined then replace data
    if (my $orig_data = $self->data) {
        %$orig_data = ();
        $orig_data->{$_} = $data->{$_} for keys %$data;
    }
    # otherwise use passed data
    else {
        $self->data($data);
    }
    # register object
    my $register = $self->_register;
    $self->collection->$register->{$self->name} = $self;

    return $self;
}

# type
#
# get/set type
sub type { shift->_get_set('type', @_) }

# waitForSync
#
# get/set waitForSync
sub waitForSync { shift->_get_set_bool('waitForSync', @_) }

# _class
#
# internal name for class
sub _class { 'document' }

# _register
#
# internal name for object index
sub _register { 'documents' }

1;

__END__


=head1 NAME

ArangoDB2::Document - ArangoDB document API methods

=head1 METHODS

=over 4

=item new

=item create

=item createCollection

=item data

=item delete

=item edges

=item get

=item head

=item keepNull

=item list

=item update

=item policy

=item replace

=item rev

=item type

=item waitForSync

=back

=head1 AUTHOR

Ersun Warncke, C<< <ersun.warncke at outlook.com> >>

http://ersun.warnckes.com

=head1 COPYRIGHT

Copyright (C) 2014 Ersun Warncke

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
