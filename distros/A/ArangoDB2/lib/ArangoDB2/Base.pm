package ArangoDB2::Base;

use strict;
use warnings;

use Carp qw(croak);
use Data::Dumper;
use JSON::XS;
use Scalar::Util qw(blessed weaken);



# new
#
# Arango organizes data hierarchically: Databases > Collections > Documents
#
# This constructor can build ArangoDB2::Database, Collection, Document, Edge,
# etc. objects which all follow the same pattern
sub new
{
    my $class = shift;
    # new instance
    my $self = {};
    bless($self, $class);
    # process args
    while (my $arg = shift) {
        # if arg is a ref it should be another
        # ArangoDB::* object
        if (ref $arg) {
            # prevent circular ref
            weaken $arg;
            # create reference to parent object
            $self->{$arg->_class} = $arg;
        }
        # if arg is a string then it is the "name"
        # of this object
        else {
            $self->name($arg);
        }
    }
    # if we have a name and can get then try it
    $self->get if defined $self->name
        and $self->can('get');

    return $self;
}

# api_path
#
# return /_db/<db name>/_api
sub api_path
{
    my $self = shift;

    my $db_name
        = $self->database
        ? $self->database->name
        : $self->name;

    return '/' . join('/', '_db', $db_name, '_api', @_);
}

# arango
#
# ArangoDB2 instance
sub arango { $_[0]->{arango} }

# collection
#
# parent ArangoDB2::Collection instance
sub collection {
    my($self, $value) = @_;

    if (defined $value) {
        # if value is already an object then set it
        if (ref $value) {
            $self->{collection} = $value;
        }
        # otherwise treat as name and get collection object
        else {
            $self->{collection} = $self->database->collection($value);
        }
    }

    return $self->{collection};
}

# data
#
# ref to hash containing document data
sub data { shift->_get_set('data', @_) }

# database
#
# parent ArangoDB2::Database instance
sub database { $_[0]->{database} }

# graph
#
# parent ArangoDB2::Graph instance
sub graph { $_[0]->{graph} }

# id
#
# ArangoDB _id
sub id { $_[0]->{id} }

# name
#
# name/handle of object
sub name { shift->_get_set_name('name', @_) }

# rev
#
# ArangoDB _rev
sub rev { $_[0]->{rev} }

# _build_args
#
# process args for requests
sub _build_args
{
    my($self, $args, $params) = @_;
    # require hash ref for args
    $args = {} unless defined $args
        and ref $args and ref $args eq 'HASH';
    # if an explicit list is not passed for this call
    # then use global list for class
    $params ||= $self->_params;
    # for each of the allowed parameters use the
    # setter to set the value if it is passed and
    # and the value to the request args if it is
    # defined
    for my $param (@$params) {
        # if params is pased in args then it supersedes
        # any value set as a property of the object
        if (exists $args->{$param}) {
            # run arg through setter with validate only
            # flag which will return the validated arg
            $args->{$param} = $self->$param($args->{$param}, 1);
        }
        # otherwise if the param is set then add to args
        elsif (defined $self->$param) {
            $args->{$param} = $self->$param;
        }
    }

    return $args;
}

# _build_self
#
# copy param values from passed data to self
sub _build_self
{
    my($self, $data, $params) = @_;
    # require data
    croak "Invalid Args"
        unless ref $data eq 'HASH';
    # if an explicit list is not passed for this call
    # then use global list for class
    $params ||= $self->_params;
    # copy params
    for my $param (@$params) {
        $self->{$param} = delete $data->{$param}
            if exists $data->{$param};
    }
    # copy _id and _rev to id/rev
    $self->{id} = delete $data->{_id}
        if exists $data->{_id};
    $self->{rev} = delete $data->{_rev}
        if exists $data->{_rev};
    # if user is set then use it as name
    if (exists $data->{user}) {
        $self->{name} = delete $data->{user};
    }
    # otherwise try _key
    elsif (exists $data->{_key}) {
        $self->{name} = delete $data->{_key}
    }
    # copy to and from
    $self->{from} = delete $data->{_from}
        if exists $data->{_from};
    $self->{to} = delete $data->{_to}
        if exists $data->{_to};

    return $self;
}

# _get_set
#
# either get or set value.
# setting value returns self.
sub _get_set
{
    my($self, $param, $value, $validate) = @_;

    if (defined $value) {
        # if we are only validating then return valid value
        return $value if $validate;
        # set value and return self
        $self->{$param} = $value;
        return $self;
    }
    else {
        # return currently set value
        return $self->{$param};
    }
}

# _get_set_bool
#
# either get value  or set JSON bool value.
# setting value returns self.
sub _get_set_bool
{
    my($self, $param, $value, $validate) = @_;

    if (defined $value) {
        # accept "true" as JSON bool false
        if ($value eq "true") {
            $value = JSON::XS::true;
        }
        # accept "false" as JSON bool false
        elsif ($value eq "false") {
            $value = JSON::XS::false;
        }
        # use the true/false of value to determine JSON bool
        else {
            $value = $value ? JSON::XS::true : JSON::XS::false;
        }
        # if we are only validating then return valid value
        return $value if $validate;
        # set value and return self
        $self->{$param} = $value;
        return $self;
    }
    else {
        # return currently set value
        return $self->{$param};
    }
}

# _get_set_id
#
# get/set id with either string or object
# setting a value returns self
sub _get_set_id
{
    my($self, $param, $value, $validate) = @_;

    if (defined $value) {
        # get value from an ArangoDB2 object
        if ( blessed $value && $value->can('id') ) {
            $value = $value->id
        }
        # if we are only validating then return valid value
        return $value if $validate;
        # set value and return self
        $self->{$param} = $value;
        return $self;
    }
    else {
        # return currently set value
        return $self->{$param};
    }
}

# _get_set_name
#
# get/set name with either name or object
# setting a value returns self
sub _get_set_name
{
    my($self, $param, $value, $validate) = @_;

    if (defined $value) {
        # get value from an ArangoDB2 object
        if ( blessed $value && $value->can('name') ) {
            $value = $value->name
        }
        # if we are only validating then return valid value
        return $value if $validate;
        # set value and return self
        $self->{$param} = $value;
        return $self;
    }
    else {
        # return currently set value
        return $self->{$param};
    }
}

1;

__END__


=head1 NAME

ArangoDB2::Base - Base class for other ArangoDB2 objects

=head1 METHODS

=over 4

=item new

=item api_path

=item arango

=item collection

=item data

=item database

=item graph

=item id

=item name

=item rev

=back

=head1 AUTHOR

Ersun Warncke, C<< <ersun.warncke at outlook.com> >>

http://ersun.warnckes.com

=head1 COPYRIGHT

Copyright (C) 2014 Ersun Warncke

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
