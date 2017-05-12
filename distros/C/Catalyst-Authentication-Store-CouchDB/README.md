# NAME

Catalyst::Authentication::Store::CouchDB - A storage class for Catalyst Authentication using CouchDB

# VERSION

version 0.001

# SYNOPSIS

    use Catalyst qw/
                    Authentication
                    Authorization::Roles/;

    __PACKAGE__->config->{authentication} =
                    {
                        default_realm => 'members',
                        realms => {
                            members => {
                                credential => {
                                    class => 'Password',
                                    password_field => 'password',
                                    password_type => 'salted_hash',
                                    password_salt_len => 4,
                                },
                                store => {
                                    class       => 'CouchDB',
                                    couchdb_uri => 'http://localhost:5984',
                                    dbname      => 'demouser',
                                    designdoc   => '_design/user',
                                    view        => 'user',
                                },
                            },
                        },
                    };

    # Log a user in:

    sub login : Global {
        my ( $self, $c ) = @_;

        $c->authenticate({
                          username => $c->req->params->{username},
                          password => $c->req->params->{password},
                          }))
    }

    # verify a role

    if ( $c->check_user_roles( 'editor' ) ) {
        # do editor stuff
    }

# DESCRIPTION

The Catalyst::Authentication::Store::CouchDB class provides access to authentication
information stored in a CouchDB instance.

# CONFIGURATION

The CouchDB authentication store is activated by setting the store
config's __class__ element to CouchDB as shown above. See the
[Catalyst::Plugin::Authentication](http://search.cpan.org/perldoc?Catalyst::Plugin::Authentication) documentation for more details on
configuring the store.

The CouchDB storage module has several configuration options

    __PACKAGE__->config->{authentication} =
                    {                      
                        default_realm => 'members',
                        realms => {
                            members => {
                                credential => {
                                    class => 'Password',
                                    password_field => 'password',
                                    password_type => 'clear'
                                },
                            store => {
                                class       => 'CouchDB',
                                couchdb_uri => 'http://localhost:5984',
                                dbname      => 'demouser',
                                designdoc   => '_design/user',
                                view        => 'user',
                            },
                        },
                    },
                };

- class

Class is part of the core Catalyst::Plugin::Authentication module; it
contains the class name of the store to be used.  This config item is __REQUIRED__.

- couchdb_uri

Contains the URI of the CouchDB instance to query.  This config item is __REQUIRED__.

- dbname

Contains the name of the database to query.  This config item is __REQUIRED__.

- designdoc

Contains the name of the CouchDB design document to query.  This config item is __REQUIRED__.

- view

Contains the name of the view in the design document to query.  The 'username' field
will be used as the key to query, and the first document retrieved will be used
to create the user model.  This config item is __REQUIRED__.

- ua

Contains the name of a class to be used for the User Agent.  This defaults
to LWP::UserAgent if not configured.  It is passed through to CouchDB::Client.

# USAGE

The [Catalyst::Authentication::Store::CouchDB](http://search.cpan.org/perldoc?Catalyst::Authentication::Store::CouchDB) storage module
is not called directly from application code.  You interface with it
through the $c->authenticate() call.

The [Catalyst::Authentication::Store::CouchDB](http://search.cpan.org/perldoc?Catalyst::Authentication::Store::CouchDB) fetches a user from CouchDB
by querying a view within a CouchDB design document.  The view is queried with
the `username` passed in the authenticate call hash as the key, and returns
a CouchDB document.  This document is then passed to
[Catalyst::Authentication::Store::CouchDB::User](http://search.cpan.org/perldoc?Catalyst::Authentication::Store::CouchDB::User) to create the user object.

A suitable view map function is

        function(doc) {
            if (doc.username) {
                emit(doc.username, null);
            }
        }

# METHODS

There are no publicly exported routines in the CouchDB authentication
store (or indeed in most authentication stores). However, below is a
description of the routines required by [Catalyst::Plugin::Authentication](http://search.cpan.org/perldoc?Catalyst::Plugin::Authentication)
for all authentication stores.  Please see the documentation for
[Catalyst::Plugin::Authentication::Internals](http://search.cpan.org/perldoc?Catalyst::Plugin::Authentication::Internals) for more information.

## new ( $config, $app )

Constructs a new store object.

## find_user ( $authinfo, $c )

Finds a user using the information provided in the $authinfo hashref and
returns the user, or undef on failure. This is usually called from the
Credential. This translates directly to a call to the User object's
load() method.

## for_session ( $c, $user )

Prepares a user to be stored in the session.  This is delegated to
the User obect for_session method.

## from_session ( $c, $frozenuser)

Revives a user from the session based on the info provided in $frozenuser.
This is delegated to the User object from_session method.

## user_supports

Provides information about what the user object supports.

# NOTES

This module is heavily based on [Catalyst::Authentication::Store::DBIx::Class](http://search.cpan.org/perldoc?Catalyst::Authentication::Store::DBIx::Class).

The test scripts use clear text passwords. __DO NOT DO THIS IN PRODUCTION.__
Use configuation as shown in the synopsis to use something stronger, such as
salted hash passwords.

The test scripts do not connect to a CouchDB instance as standard - they 
mock the responses that CouchDB would send.  To connect to a CouchDB instance,
set the `CATALYST_COUCHDB_LIVE` environment variable before running the test suite.
The test suite assumes that a `demouser` database exists, with a design document
called `user` that contains a `user` view, and that a document listing a test
user with username `test` and password `test` exists.  To configure this,
run the `setup_database.pl` script in the `t/script` directory on the distribution.
__This script will remove any existing demouser database.__

# BUGS AND LIMITATIONS

There are bound to be bugs - please email the author if you find any.

# SEE ALSO

[Catalyst::Authentication::Store::DBIx::Class](http://search.cpan.org/perldoc?Catalyst::Authentication::Store::DBIx::Class).
[Catalyst::Plugin::Authentication](http://search.cpan.org/perldoc?Catalyst::Plugin::Authentication),
[Catalyst::Plugin::Authentication::Internals](http://search.cpan.org/perldoc?Catalyst::Plugin::Authentication::Internals),
and [Catalyst::Plugin::Authorization::Roles](http://search.cpan.org/perldoc?Catalyst::Plugin::Authorization::Roles)

# AUTHOR

Colin Bradford <cjbradford@gmail.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Colin Bradford.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.