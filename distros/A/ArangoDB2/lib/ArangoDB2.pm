package ArangoDB2;

use strict;
use warnings;

use base qw(
    ArangoDB2::Base
);

our $VERSION = '0.11';

use URI;

use ArangoDB2::Admin;
use ArangoDB2::Database;
use ArangoDB2::Endpoint;
use ArangoDB2::HTTP;



# new
#
# create new ArangoDB2 instance from string argument specifying
# API endpoint or hashref of args
sub new
{
    my($class, $uri, $username, $password) = @_;
    # create instance
    my $self = {};
    bless($self, $class);
    # set values
    $self->uri($uri);
    $self->username($username);
    $self->password($password);

    return $self;
}

# admin
#
# ArangoDB2::Admin object which provides access to methods in
# the /_admin group
sub admin
{
    my($self) = @_;

    return ArangoDB2::Admin->new($self);
}

# database
#
# ArangoDB2::Database object which provides access to methods
# in the /_api/database group
sub database
{
    my($self, $name) = @_;
    # default database for arango is _system
    $name ||= "_system";
    # only create one instance per ArangoDB2 per database, each ArangoDB2
    # keeps its own instances since they may have different credentials
    return $self->databases->{$name} ||= ArangoDB2::Database->new($self, $name);
}

# databases
#
# Index of active ArangoDB2::Database objects by name
sub databases { $_[0]->{databases} ||= {} }

# endpoint
#
# ArangoDB2::Endpoint object
sub endpoint
{
    my($self, $name) = @_;

    return ArangoDB2::Endpoint->new($self, $name);
}

# http
#
# ArangoDB2::HTTP object.  This provides normalized interface to
# various HTTP clients.
sub http
{
    my($self, $http) = @_;

    $self->{http} = $http
        if defined $http;

    return $self->{http} ||= ArangoDB2::HTTP->new($self);
}

# http_client
#
# set string indicating http client to use
sub http_client {
    my($self) = shift;
    # get/set http client value
    my $http_client = $self->_get_set('http_client', @_)
        or return;
    # flush current http client instance so that it will be
    # re-created using the correct client
    $self->{http} = undef;

    return $http_client;
}

# uri
#
# get/set URI for API
sub uri
{
    my($self, $uri) = @_;

    $self->{uri} = URI->new($uri)
        if defined $uri;

    return $self->{uri};
}

# version
#
# GET /_api/version
#
# Returns the server name and version number. The response is a JSON object with the following attributes:
#
# server: will always contain arango
# version: the server version string. The string has the format "major.minor.sub". major and minor will be numeric, and sub may contain a number or a textual version.
# details: an optional JSON object with additional details. This is returned only if the details URL parameter is set to true in the request.
sub version
{
    my($self) = @_;

    return $self->http->get('/_api/version');
}

####################
# PROPERTY METHODS #
####################

sub username { shift->_get_set('username', @_) }
sub password { shift->_get_set('password', @_) }

####################
# INTERNAL METHODS #
####################

# _class
#
# internal name for class
sub _class { 'arango' }

1;

__END__

=head1 NAME

ArangoDB2 - ArangoDB 2.x HTTP API Interface

=head1 SYNOPSIS

    my $arango = ArangoDB2->new('http://localhost:8259', 'username', 'password');

    $arango->database('foo')->create;
    $aragno->database('foo')->collection('bar')->create;

    my $doc = $arango->database('foo')->collection('bar')->document->create({
        hello => 'world'
    });

    $doc->update({hello => 'bob'});

=head1 DESCRIPTION

ArangoDB2 implements the ArangoDB 2.x HTTP API interface.

Most of the API surface is implemented with the exception of:

    Async Results
    Bulk Imports
    Batch Requests
    Sharding
    Simple Queries

The use of ETags to control modification operations has not been implemented.

The public interface should be stable at this point.  The internal plumbing will
likely continue to evolve.

See the official docs for details on the API: L<https://docs.arangodb.com>

=head1 CONVENTIONS

Parameters for API calls can be set either with setter methods or as arguments to
the method call.

    $arango->database->name('foo')->create;
    $arango->database->create({name => 'foo'});

The major difference between these two approaches is that when a parameter is passed
as an argument it is not stored.  If a parameter is set on the object, then subsequent
requests will continue to use that parameter.

    # collection will be created
    $doc1->createCollection(1)->create({foo => 'bar'});
    # collection will also be created
    $doc1->create({foo => 'bar'});

    # collection will be created
    $doc2->create({foo => 'bar'}, {createCollection => 1});
    # collection will not be created
    $doc2->create({foo => 'bar'});

Databases, collections, documents, indexes, and other objects are registered and cached
by name.  This will be made optional in the future.

    # creates a new instance of database
    $db = $arango->database('foo');
    # returns the previously created instance
    $arango->database('foo');

When you retrieve a document, edge, or other object by name this may result in a GET query to
fetch the details for that object.  If you use the name method to set the name of the object
after it is created this GET can be avoided.

    # performs a GET
    $doc1 = $collection->document('foo');
    # does not perform a GET
    $doc2 = $collection->document->name('foo');

When you access an object by name this will return an existing cached version of the object if
it exists.  If you leave out the name this will bypass the object register / cache.

    # uses cached object if it exists
    $doc1 = $collection->document('foo');
    # does not use cached object even it it exists
    $doc2 = $collection->document->name('foo');

Wherever possible the naming of methods and parameters has been kept the same as the names used
by the API.  The structure of ArangoDB2 attempts to mirror the structure of the API as closely
as possible.  This should make it easy to refer to the official ArangoDB API documentation when
using ArangoDB2.

ArangoDB2 does not attempt to validate parameters.  The only validation that takes place is to
insure that bool parameters have properly encoded JSON true and false values.

=head1 METHODS

=over 4

=item new

=item admin

=item database

=item databases

=item endpoint

=item http

=item http_client

Get/set string indicating which HTTP backend to use.  Currently supported values are 'lwp' and
'curl'.  Using curl requires L<WWW::Curl>, which will be used by default if it is installed.

=back

=head1 API METHODS

=over 4

=item version

GET /_api/version

Returns the server name and version number.

=back

=head1 PROPERTY METHODS

=over 4

=item uri

L<URI> of ArangoDB endpoint.

=item password

Password to use when accessing ArangoDB.

=item username

Username to use when accessing ArangoDB.

=back

=head1 SEE ALSO

L<ArangoDB>

=head1 AUTHOR

Ersun Warncke, C<< <ersun.warncke at outlook.com> >>

http://ersun.warnckes.com

=head1 COPYRIGHT

Copyright (C) 2014 Ersun Warncke

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
