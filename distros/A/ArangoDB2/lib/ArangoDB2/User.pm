package ArangoDB2::User;

use strict;
use warnings;

use base qw(
    ArangoDB2::Base
);

use Data::Dumper;
use JSON::XS;

my $JSON = JSON::XS->new->utf8;

my @PARAMS = qw(
    active changePassword extra name passwd
);



###############
# API METHODS #
###############

# create
#
# POST /_api/user
sub create
{
    my($self, $args) = @_;
    # process request args
    $args = $self->_build_args($args, \@PARAMS);
    # use name for user param
    $args->{user} = delete $args->{name};
    # make request
    my $res = $self->arango->http->post(
        $self->api_path('user'),
        undef,
        $JSON->encode($args),
    ) or return;
    # if request was success copy args to self
    $self->_build_self($res, \@PARAMS);

    return $self;
}

# delete
#
# DELETE /_api/user/{user}
sub delete
{
    my($self, $args) = @_;
    # process request args
    $args = $self->_build_args($args, ['name']);
    # make request
    return $self->arango->http->delete(
        $self->api_path('user', delete $args->{name}),
    ) or return;
}

# get
#
# GET /_api/user/{user}
sub get
{
    my($self, $args) = @_;
    # process request args
    $args = $self->_build_args($args, ['name']);
    # make request
    my $res = $self->arango->http->get(
        $self->api_path('user', delete $args->{name}),
    ) or return;
    # copy param data from res to self
    $self->_build_self($res, \@PARAMS);

    return $self;
}

# update
#
# PATCH /_api/user/{user}
sub update
{
    my($self, $args) = @_;
    # process request args
    $args = $self->_build_args($args, \@PARAMS);
    # make request
    my $res = $self->arango->http->patch(
        $self->api_path('user', delete $args->{name}),
        undef,
        $JSON->encode($args),
    ) or return;
    # if request was success copy args to self
    $self->_build_self($res, \@PARAMS);

    return $self;
}

# replace
#
# PUT /_api/user/{user}
sub replace
{
    my($self, $args) = @_;
    # process request args
    $args = $self->_build_args($args, \@PARAMS);
    # make request
    my $res = $self->arango->http->put(
        $self->api_path('user', delete $args->{name}),
        undef,
        $JSON->encode($args),
    ) or return;
    # if request was success copy args to self
    $self->_build_self($res, \@PARAMS);

    return $self;
}

####################
# PROPERTY METHODS #
####################

sub active { shift->_get_set_bool('active', @_) }

sub changePassword  { shift->_get_set_bool('changePassword', @_) }

sub extra { shift->_get_set('extra', @_) }

sub passwd { shift->_get_set('passwd', @_) }

1;

__END__

=head1 NAME

ArangoDB2::User - ArangoDB user API methods

=head1 DESCRIPTION

=head1 API METHODS

=over 4

=item create

POST /_api/user

Create new user.

Parameters:
    active
    changePassword
    extra
    name
    passwd

=item delete

DELETE /_api/user/{name}

Removes an existing user.

Parameters:
    name

=item get

GET /_api/user/{name}

Fetches data about the specified user.

Parameters:
    name

=item update

PATCH /_api/user/{user}

Partially updates the data of an existing user.

Parameters:
    active
    changePassword
    extra
    name
    passwd

=item replace

PUT /_api/user/{user}

Replaces the data of an existing user.

Parameters:
    active
    changePassword
    extra
    name
    passwd

=back

=head1 PROPERTY METHODS

=over 4

=item active

An optional flag that specifies whether the user is active

=item changePassword

An optional flag that specifies whethers the user must change the password or not.

=item extra

An optional JSON object with arbitrary extra data about the user

=item passwd

The user password as a string. If no password is specified, the empty string will be used.

=item name

The name of the user as a string.

=back

=head1 AUTHOR

Ersun Warncke, C<< <ersun.warncke at outlook.com> >>

http://ersun.warnckes.com

=head1 COPYRIGHT

Copyright (C) 2014 Ersun Warncke

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
