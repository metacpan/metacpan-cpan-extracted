package ArangoDB2::Graph::Vertex;

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
# POST /_api/gharial/graph-name/vertex/collection-name
sub create
{
    my($self, $data, $args) = @_;
    # require data
    die "Invlalid args"
        unless ref $data eq 'HASH';
    # process args
    $args = $self->_build_args($args, ['waitForSync']);
    # make request
    my $res = $self->arango->http->post(
        $self->api_path('gharial', $self->graph->name, $self->_class, $self->collection->name),
        $args,
        $JSON->encode($data),
    ) or return;
    # get response data
    $res = $res->{$self->_class}
        or return;
    # copy response data to instance
    $self->_build_self($res, []);
    # set data pointer to passed in doc, which will
    # be updated by future object ops
    $self->{data} = $data;
    # register object
    my $register = $self->_register;
    $self->collection->$register->{$self->name} = $self;

    return $self;
}

# delete
#
# DELETE /system/gharial/graph-name/vertex/collection-name/vertex-key
sub delete
{
    my($self, $args) = @_;
    # process args
    $args = $self->_build_args($args, ['name', 'waitForSync']);
    # make request
    my $res = $self->arango->http->delete(
        $self->api_path('gharial', $self->graph->name, $self->_class, $self->collection->name, delete $args->{name}),
    ) or return;
    # empty data
    if (my $data = $self->data) {
        %$data = ();
    }
    # unregister object
    my $register = $self->_register;
    delete $self->collection->$register->{$self->name};

    return $res;
}

# get
#
# GET /system/gharial/graph-name/vertex/collection-name/vertex-key
sub get
{
    my($self, $args) = @_;
    # process args
    $args = $self->_build_args($args, ['data', 'name']);
    # make request
    my $res = $self->arango->http->get(
        $self->api_path('gharial', $self->graph->name, $self->_class, $self->collection->name, delete $args->{name}),
    ) or return;
    # get response data
    $res = $res->{$self->_class}
        or return;
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

    return $self;
}

# keepNull
#
# get/set keepNull
sub keepNull { shift->_get_set_bool('keepNull', @_) }

# update
#
# PATCH /system/gharial/graph-name/vertex/collection-name/vertex-key
sub update
{
    my($self, $data, $args) = @_;
    # require data
    die "Invalid args"
        unless ref $data eq 'HASH';
    # process args
    $args = $self->_build_args($args, ['name', 'keepNull', 'waitForSync']);
    # make request
    my $res = $self->arango->http->patch(
        $self->api_path('gharial', $self->graph->name, $self->_class, $self->collection->name, delete $args->{name}),
        $args,
        $JSON->encode($data),
    ) or return;
    # get response data
    $res = $res->{$self->_class}
        or return;
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

# replace
#
# PUT /system/gharial/graph-name/vertex/collection-name/vertex-key
sub replace
{
    my($self, $data, $args) = @_;
    # require data
    die "Invlalid args"
        unless ref $data eq 'HASH';
    # process args
    $args = $self->_build_args($args, ['name', 'waitForSync']);
    # make request
    my $res = $self->arango->http->put(
        $self->api_path('gharial', $self->graph->name, $self->_class, $self->collection->name, delete $args->{name}),
        $args,
        $JSON->encode($data),
    ) or return;
    # get response data
    $res = $res->{$self->_class}
        or return;
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

# waitForSync
#
# get/set waitForSync
sub waitForSync { shift->_get_set_bool('waitForSync', @_) }

# _class
#
# internal name for class
sub _class { 'vertex' }

# _register
#
# internal name for object index
sub _register { 'vertices' }

1;

__END__

=head1 NAME

ArangoDB2::Graph::Vertex - ArangoDB vertex API methods

=head1 DESCRIPTION

Graph vertexes are really documents and so all of the access methods
here are the same as ArangoDB::Document.

=head1 METHODS

=over 4

=item new

=item create

=item delete

=item get

=item keepNull

=item update

=item replace

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
