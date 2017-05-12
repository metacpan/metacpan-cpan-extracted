package ArangoDB2::Endpoint;

use strict;
use warnings;

use base qw(
    ArangoDB2::Base
);

use Data::Dumper;
use JSON::XS;
use URI::Escape qw(uri_escape);

my $JSON = JSON::XS->new->utf8;



###############
# API METHODS #
###############

# create
#
# POST /_api/endpoint
sub create
{
    my($self, $args) = @_;
    # process request args
    $args = $self->_build_args($args, ['name', 'databases']);
    # use name for endpoint param
    $args->{endpoint} = $args->{name};
    # make request
    my $res = $self->arango->http->post(
        '/_api/endpoint',
        undef,
        $JSON->encode($args),
    ) or return;
    # if request was success copy args to self
    $self->_build_self($args, ['name', 'databases']);

    return $self;
}

# delete
#
# DELETE /_api/endpoint/{name}
sub delete
{
    my($self, $args) = @_;
    # process request args
    $args = $self->_build_args($args, ['name']);
    # make request
    return $self->arango->http->delete(
        '/_api/endpoint/'.uri_escape( $args->{name} )
    );
}

# list
#
# GET /_api/endpoint
sub list
{
    my($self) = @_;

    return $self->arango->http->get('/_api/endpoint');
}

####################
# PROPERTY METHODS #
####################

sub databases { shift->_get_set('databases', @_) }

1;

__END__

=head1 NAME

ArangoDB2::Endpoint - ArangoDB endpoint API methods

=head1 DESCRIPTION

=head1 API METHODS

=over 4

=item create

POST /_api/endpoint

Connects a new endpoint or reconfigures an existing endpoint.

Parameters:

    name
    databases

=item delete

DELETE /_api/endpoint/{endpoint}

Parameters:

    name

=item list

GET /_api/endpoint

Returns a list of all configured endpoints the server is listening on.

=back

=head1 PROPERTY METHODS

=over 4

=item name

the endpoint specification, e.g. tcp://127.0.0.1:8530

=item databases

a list of database names the endpoint is responsible for.

=back

=head1 AUTHOR

Ersun Warncke, C<< <ersun.warncke at outlook.com> >>

http://ersun.warnckes.com

=head1 COPYRIGHT

Copyright (C) 2014 Ersun Warncke

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
