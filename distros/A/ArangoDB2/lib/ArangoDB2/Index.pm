package ArangoDB2::Index;

use strict;
use warnings;

use base qw(
    ArangoDB2::Base
);

use Data::Dumper;
use JSON::XS;

# parameters that can be set when creating index or
# are returned when creating/getting index
our @PARAMS = qw(
    byteSize constraint fields geoJson id ignoreNull
    isNewlyCreated minLength size type unique
);

my $JSON = JSON::XS->new->utf8;



# byteSize
#
# get/set byteSize
sub byteSize { shift->_get_set('byteSize', @_) }

# constraint
#
# get/set constraint value
sub constraint { shift->_get_set_bool('constraint', @_) }

# create
#
# POST /_api/index
sub create
{
    my($self, $index, $args) = @_;
    # require index
    die "Invalid Args"
        unless ref $index eq 'HASH';
    # process args
    $args = $self->_build_args($args, \@PARAMS);
    # set collection name
    $args->{collection} = $self->collection->name;
    # make request
    my $res = $self->arango->http->post(
        $self->api_path('index'),
        $args,
        $JSON->encode($index),
    ) or return;
    # get name from id
    my($name) = $res->{id} =~ m{/(\d+)$}
        or return;
    $self->{name} = $name;
    # copy response data to instance
    $self->_build_self($res, \@PARAMS);
    # register
    $self->collection->indexes->{$name} = $self;

    return $self;
}

# delete
#
# DELETE /_api/index/{index-handle}
sub delete
{
    my($self) = @_;
    # make request
    my $res = $self->arango->http->delete(
        $self->api_path('index', $self->id),
    ) or return;
    # remove from register
    delete $self->collection->indexes->{$self->name};

    return $res;
}

# fields
#
# get/set fields
sub fields { shift->_get_set('fields', @_) }

# geoJson
#
# get/set geoJson value
sub geoJson { shift->_get_set_bool('geoJson', @_) }

# get
#
# GET /_api/index/{index-handle}
sub get
{
    my($self, $args) = @_;
    # process args
    $args = $self->_build_args($args, ['name']);
    # use either id or name
    my $id = $self->id
        ? $self->id
        :  join('/', $self->collection->name, delete $args->{name});
    # make request
    my $res = $self->arango->http->get(
        $self->api_path('index', $id),
    ) or return;
    # get name from id
    my($name) = $res->{id} =~ m{/(\d+)$}
        or return;
    $self->{name} = $name;
    # copy response data to instance
    $self->_build_self($res, \@PARAMS);
    # register
    $self->collection->indexes->{$name} = $self;

    return $self;
}

# ignoreNull
#
# get/set ignoreNull value
sub ignoreNull { shift->_get_set_bool('ignoreNull', @_) }

# isNewlyCreated
#
# get isNewlyCreated value
sub isNewlyCreated { $_[0]->{isNewlyCreated} }

# list
#
# GET /_api/index
sub list
{
    my($self, $args) = @_;
    # set default args
    $args ||= {};
    # require valid args
    die 'Invalid Args'
        unless ref $args eq 'HASH';

    $args->{collection} ||= $self->collection->name;

    return $self->arango->http->get(
        $self->api_path('index'),
        $args
    );
}

# minLength
#
# get/set minLength
sub minLength { shift->_get_set('minLength', @_) }

# size
#
# get/set size
sub size { shift->_get_set('size', @_) }

# type
#
# get/set type
sub type { shift->_get_set('type', @_) }

# unique
#
# get/set unique value
sub unique { shift->_get_set_bool('unique', @_) }

1;

__END__

=head1 NAME

ArangoDB2::Index - ArangoDB index API methods

=head1 METHODS

=over 4

=item new

=item byteSize

=item constraint

=item create

=item delete

=item fields

=item geoJson

=item get

=item id

=item ignoreNull

=item isNewlyCreated

=item list

=item minLength

=item size

=item type

=item unique

=back

=head1 AUTHOR

Ersun Warncke, C<< <ersun.warncke at outlook.com> >>

http://ersun.warnckes.com

=head1 COPYRIGHT

Copyright (C) 2014 Ersun Warncke

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
