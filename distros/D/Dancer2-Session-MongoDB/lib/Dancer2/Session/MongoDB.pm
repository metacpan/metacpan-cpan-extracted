use 5.008001;
use strict;
use warnings;

package Dancer2::Session::MongoDB;
# ABSTRACT: Dancer 2 session storage with MongoDB
our $VERSION = '0.004';

use Moo;
use MongoDB::MongoClient;
use MongoDB::OID;
use Dancer2::Core::Types;

#--------------------------------------------------------------------------#
# Public attributes
#--------------------------------------------------------------------------#

#pod =attr database_name (required)
#pod
#pod Name of the database to hold the sessions collection.
#pod
#pod =cut

has database_name => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

#pod =attr collection_name
#pod
#pod Collection name for storing session data. Defaults to 'dancer_sessions'.
#pod
#pod =cut

has collection_name => (
    is      => 'ro',
    isa     => Str,
    default => sub { "dancer_sessions" },
);

#pod =attr client_options
#pod
#pod Hash reference of configuration options to pass through to
#pod L<MongoDB::MongoClient> constructor.  See that module for details on
#pod configuring authentication, replication, etc.
#pod
#pod =cut

has client_options => (
    is      => 'ro',
    isa     => HashRef,
    default => sub { {} },
);

#--------------------------------------------------------------------------#
# Private attributes
#--------------------------------------------------------------------------#

has _client => (
    is  => 'lazy',
    isa => InstanceOf ['MongoDB::MongoClient'],
);

sub _build__client {
    my ($self) = @_;
    return MongoDB::MongoClient->new( $self->client_options );
}

has _collection => (
    is  => 'lazy',
    isa => InstanceOf ['MongoDB::Collection'],
);

sub _build__collection {
    my ($self) = @_;
    my $db = $self->_client->get_database( $self->database_name );
    return $db->get_collection( $self->collection_name );
}

#--------------------------------------------------------------------------#
# Role composition
#--------------------------------------------------------------------------#

with 'Dancer2::Core::Role::SessionFactory';

# When saving/retrieving, we need to add/strip the _id parameter
# because the Dancer2::Core::Session object keeps them as separate
# attributes

sub _retrieve {
    my ( $self, $id ) = @_;
    my $doc = $self->_collection->find_one( { _id => $id } );
    return $doc->{data};
}

sub _flush {
    my ( $self, $id, $data ) = @_;
    $self->_collection->save( { _id => $id, data => $data }, { safe => 1 } );
}

sub _destroy {
    my ( $self, $id ) = @_;
    $self->_collection->remove( { _id => $id }, { safe => 1 } );
}

sub _sessions {
    my ($self) = @_;
    my $cursor = $self->_collection->query->fields( { _id => 1 } );
    return [ map { $_->{_id} } $cursor->all ];
}

sub _change_id {
    my ( $self, $old_id, $new_id ) = @_;
    $self->_flush( $new_id, $self->_retrieve( $old_id ) );
    $self->_destroy( $old_id );
}

1;


# vim: ts=4 sts=4 sw=4 et:

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer2::Session::MongoDB - Dancer 2 session storage with MongoDB

=head1 VERSION

version 0.004

=head1 SYNOPSIS

  # In Dancer 2 config.yml file

  session: MongoDB
  engines:
    session:
      MongoDB:
        database_name: myapp_db
        client_options:
          host: mongodb://localhost:27017

=head1 DESCRIPTION

This module implements a session factory for Dancer 2 that stores session
state within L<MongoDB>.

=head1 ATTRIBUTES

=head2 database_name (required)

Name of the database to hold the sessions collection.

=head2 collection_name

Collection name for storing session data. Defaults to 'dancer_sessions'.

=head2 client_options

Hash reference of configuration options to pass through to
L<MongoDB::MongoClient> constructor.  See that module for details on
configuring authentication, replication, etc.

=for Pod::Coverage method_names_here

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/PerlDancer/dancer2-session-mongodb/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/PerlDancer/dancer2-session-mongodb>

  git clone https://github.com/PerlDancer/dancer2-session-mongodb.git

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 CONTRIBUTORS

=for stopwords Jason A. Crome Peter Mottram

=over 4

=item *

Jason A. Crome <jason@crome-plated.com>

=item *

Peter Mottram <peter@sysnix.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
