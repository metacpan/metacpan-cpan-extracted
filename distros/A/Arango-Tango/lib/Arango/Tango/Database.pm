# ABSTRACT: ArangoDB Database object

package Arango::Tango::Database;
$Arango::Tango::Database::VERSION = '0.009';
use Arango::Tango::Cursor;

use warnings;
use strict;

sub _new {
    my ($class, %opts) = @_;
    return bless {%opts} => $class;
}

sub collection {
   my ($self, $name) = @_;
   my @match = grep { $_->{name} eq $name } @{$self->list_collections};
   if (scalar(@match)) {
      return Arango::Tango::Collection->_new(arango => $self->{arango}, database => $self->{name}, 'name' => $name);
   }
   else {
      die "Arango::Tango | Collection not found in database $self->{name}."
   }
}

sub cursor {
    my ($self, $aql, %opts) = @_;
    return Arango::Tango::Cursor->_new(arango => $self->{arango}, database => $self->{name}, query => $aql, %opts);
}

sub list_collections {
    my ($self) = @_;
    return $self->{arango}->list_collections($self->{name});
}

sub create_collection {
    my ($self, $name) = @_;
    die "Arango::Tango | Cannot create collection with empty collection or database name" unless length $name;
    return $self->{arango}->_api('create_collection', { database => $self->{name}, name => $name })
}

sub delete_collection {
    my ($self, $name) = @_;
    die "Arango::Tango | Cannot create collection with empty collection or database name" unless length $name;
    return $self->{arango}->_api('delete_collection', { database => $self->{name}, name => $name })
}

sub delete {
    my $self = shift;
    return $self->{arango}->delete_database($self->{name});
}

sub get_access_level {
    my ($self, $username, $collection) = @_;
    return $self->{arango}->get_access_level($self->{name}, $username, $collection);
}

sub clear_access_level {
    my ($self, $username, $collection) = @_;
    return $self->{arango}->clear_access_level($self->{name}, $username, $collection);
}

sub set_access_level {
    my ($self, $username, $grant, $collection) = @_;
    return $self->{arango}->set_access_level($self->{name}, $username, $grant, $collection);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Arango::Tango::Database - ArangoDB Database object

=head1 VERSION

version 0.009

=head1 USAGE

This class should not be created directly. The L<Arango::Tango> module is responsible for
creating instances of this object.

C<Arango::Tango::Database> answers to the following methods:

=head2 C<list_collections>

   my $cols = $database->list_collections;

Returns an array reference to the collections available in the database.

=head2 C<create_collection>

   my $col = $database->create_collection("col_name");

Creates a new collection and returns the object representing it (L<Arango::Tango::Collection>).

=head2 C<collection>

    my $collection = $database->collection("some_collection");

Opens an existing collection, and returns a reference to a L<Arango::Tango::Collection> representing it.

=head2 C<delete_collection>

   $database->delete_collection("col_name");

Deletes a collection.

=head2 C<cursor>

   my $cursor = $database->cursor( $aql_query, %opt );

Performs AQL queries, returning a cursor. An optional hash of
options can be supplied. Supported hashes corresponde to the different attributes
available in the ArangoDB REST API (L<https://docs.arangodb.com/3.4/HTTP/AqlQueryCursor/AccessingCursors.html>).

=head2 C<delete>

    $db->delete;

Deletes the supplied database.

=head2 C<get_access_level>

    $perms = $db->get_access_level($user)
    $perms = $db->get_access_level($collection, $user)

Fetch the database or collection access level for a specific user.

=head2 C<set_access_level>

    $db->set_access_level($user, "rw")
    $db->set_sccess_level($collection, $user, "ro")

Set the database or collection access level for a specific user.

=head2 C<clear_access_level>

    $db->clear_access_level($user)
    $db->clear_sccess_level($collection, $user)

Clears the database or collection access level for a specific user.

=head1 AUTHOR

Alberto Simões <ambs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Alberto Simões.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
