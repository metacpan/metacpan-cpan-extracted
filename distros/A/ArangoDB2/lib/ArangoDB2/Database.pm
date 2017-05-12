package ArangoDB2::Database;

use strict;
use warnings;

use base qw(
    ArangoDB2::Base
);

use Data::Dumper;
use JSON::XS;
use Scalar::Util qw(reftype);

use ArangoDB2::Collection;
use ArangoDB2::Graph;
use ArangoDB2::Query;
use ArangoDB2::Replication;
use ArangoDB2::Transaction;
use ArangoDB2::User;

my $JSON = JSON::XS->new->utf8;



# collection
#
# get/create ArangoDB2::Collection object
sub collection
{
    my($self, $name) = @_;

    if (defined $name) {
        # only create one ArangoDB2::Collection instance per name
        return $self->collections->{$name} ||= ArangoDB2::Collection->new(
            $self->arango,
            $self,
            $name,
        );
    }
    else {
        ArangoDB2::Collection->new(
            $self->arango,
            $self,
            $name,
        );
    }
}

# collections
#
# index of ArangoDB2::Collection objects by name
sub collections { $_[0]->{collections} ||= {} }

# create
#
# POST /_api/database
sub create
{
    my($self, $args) = @_;
    # process args
    $args = $self->_build_args($args, ['name','users']);
    # make request
    my $res = $self->arango->http->post(
        '/_api/database',
        undef,
        $JSON->encode($args),
    ) or return;

    return $self;
}

# current
#
# GET /_api/database/current
sub current
{
    my($self) = @_;

    return $self->arango->http->get('/_api/database/current');
}

# delete
#
# DELETE /_api/database/{database-name}
sub delete
{
    my($self) = @_;

    return $self->arango->http->delete("/_api/database/".$self->name);
}

# graph
#
# get/create ArangoDB2::Graph object
sub graph
{
    my($self, $name) = @_;

    if (defined $name) {
        return $self->graphs->{$name} ||= ArangoDB2::Graph->new(
            $self->arango,
            $self,
            $name,
        );
    }
    else {
        return ArangoDB2::Graph->new(
            $self->arango,
            $self,
        );
    }
}

# graphs
#
# index of ArangoDB2::Graph objects by name
sub graphs { $_[0]->{graphs} ||= {} }

# list
#
# GET /_api/database
#
# Retrieves the list of all existing databases
sub list
{
    my($self) = @_;

    return $self->arango->http->get('/_api/database');
}


# query
#
# get a new ArangoDB2::Query object
sub query
{
    my($self, $query) = @_;

    return ArangoDB2::Query->new(
        $self->arango,
        $self,
        $query
    );
}

# replication
#
# get a new ArangoDB2::Replication object
sub replication
{
    my($self) = @_;

    return ArangoDB2::Replication->new(
        $self->arango,
        $self,
    );
}

# transaction
#
# get a new ArangoDB2::Transaction object
sub transaction
{
    my($self) = @_;

    return ArangoDB2::Transaction->new(
        $self->arango,
        $self,
    );
}

# user
#
# ArangoDB2::User object
sub user
{
    my($self, $name) = @_;

    return ArangoDB2::User->new(
        $self->arango,
        $self,
        $name,
    );
}

# userDatabases
#
# GET /_api/database/user
#
# Retrieves the list of all databases the current user can access without specifying
# a different username or password.
sub userDatabases
{
    my($self) = @_;

    return $self->arango->http->get('/_api/database/user');
}

# users
#
# get/set users
sub users { shift->_get_set('users', @_) }

# _class
#
# internal name for class
sub _class { 'database' }

1;

__END__

=head1 NAME

ArangoDB2::Database - ArangoDB database API methods

=head1 METHODS

=over 4

=item new

=item collection

=item collections

=item create

=item current

=item delete

=item graph

=item graphs

=item list

=item query

=item replication

=item transaction

=item user

=item userDatabases

=item users

=back

=head1 AUTHOR

Ersun Warncke, C<< <ersun.warncke at outlook.com> >>

http://ersun.warnckes.com

=head1 COPYRIGHT

Copyright (C) 2014 Ersun Warncke

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
