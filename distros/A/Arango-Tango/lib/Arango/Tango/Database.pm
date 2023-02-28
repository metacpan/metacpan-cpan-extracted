# ABSTRACT: ArangoDB Database object

package Arango::Tango::Database;
$Arango::Tango::Database::VERSION = '0.019';
use Arango::Tango::Cursor;
use Arango::Tango::API;

use warnings;
use strict;

BEGIN {
    Arango::Tango::API::_install_methods "Arango::Tango::Database" => {

        delete_collection => {
            rest => [ delete => '{{database}}_api/collection/{colname}' ],
            signature => [ 'colname' ],
            inject_properties => [ { prop => 'name', as => 'database' } ],
        },

        get_indexes => {
            rest => [ get => '{{database}}_api/index?collection={colname}' ],
            signature => [ 'colname' ],
            inject_properties => [ { prop => 'name', as => 'database' } ]
        },

        create_ttl_index => {
            rest => [ post => '{{database}}_api/index?collection={colname}' ],
            signature => [ 'colname' ],
            inject_properties => [ { prop => 'name', as => 'database' } ],
            schema => {
                name => { type => 'string' },
                type => { type => 'string', enum => ['ttl'] },
                fields => { type => 'array', items => { type => 'string' } },
                expireAfter => { type => 'integer' }
            }
        },

        create_collection => {
            rest => [ post => '{{database}}_api/collection' ],
            schema => {
                keyOptions => { type => 'object', additionalProperties => 0, params => {
                    allowUserKeys => { type => 'boolean' },
                    type          => { type => 'string', default => 'traditional', enum => [qw'traditional autoincrement uuid padded'] },
                    increment     => { type => 'integer' },
                    offset        => { type => 'integer' },
                }},
                journalSize       => { type => 'integer' },
                replicationFactor => { type => 'integer' },
                waitForSync       => { type => 'boolean' },
                doCompact         => { type => 'boolean' },
                shardingStrategy  => {
                    type    => 'string',
                    default => 'community-compat',
                    enum    => ['community-compat', 'enterprise-compat', 'enterprise-smart-edge-compat', 'hash', 'enterprise-hash-smart-edge']},
                isVolatile        => { type => 'boolean' },
                shardKeys         => { type => 'array', items => {type => 'string'} },
                numberOfShards    => { type => 'integer' },
                isSystem          => { type => 'boolean' },
                type              => { type => 'string', default => '2', enum => ['2', '3'] },
                indexBuckets      => { type => 'integer' },
                distributeShardsLike => { type => 'string' },
                name              => { type => 'string' }
            },
            builder => sub {
                my ($self, %params) = @_;
                return Arango::Tango::Collection->_new(arango => $self, database => $params{database}, 'name' => $params{name});
            },
            signature => [ 'name' ],
            inject_properties => [ { prop => 'name', as => 'database' } ]
        }

    };
}

sub _new {
    my ($class, %opts) = @_;
    return bless {%opts} => $class;
}

sub delete {
    my $self = shift;
    return $self->{arango}->delete_database($self->{name});
}

sub cursor {
    my ($self, $aql, %opts) = @_;
    return Arango::Tango::Cursor->_new(arango => $self->{arango}, database => $self->{name}, query => $aql, %opts);
}





sub collection {
   my ($self, $name) = @_;
   my @match = grep { $_->{name} eq $name } @{$self->list_collections};
   if (scalar(@match)) {
      return Arango::Tango::Collection->_new(arango => $self->{arango}, database => $self->{name}, 'name' => $name,);
   }
   else {
      die "Arango::Tango | Collection not found in database $self->{name}."
   }
}

sub list_collections {
    my ($self, %opts) = @_;
    return $self->{arango}->_api( list_collections => {  %opts, database => $self->{name} } )->{result};
}


sub get_access_level {
    my ($self, $username, $collection) = @_;
    return $self->{arango}->get_access_level( $username, $self->{name}, $collection);
}

sub clear_access_level {
    my ($self, $username, $collection) = @_;
    return $self->{arango}->clear_access_level($username, $self->{name},  $collection);
}

sub set_access_level {
    my ($self, $username, $grant, $collection) = @_;
    return $self->{arango}->set_access_level($username, $grant, $self->{name},  $collection);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Arango::Tango::Database - ArangoDB Database object

=head1 VERSION

version 0.019

=head1 USAGE

This class should not be created directly. The L<Arango::Tango> module is responsible for
creating instances of this object.

C<Arango::Tango::Database> answers to the following methods:

=head2 C<collection>

    my $collection = $database->collection("some_collection");

Opens an existing collection, and returns a reference to a L<Arango::Tango::Collection> representing it.

=head2 C<clear_access_level>

    $db->clear_access_level($user)
    $db->clear_access_level($user, $collection)

Clears the database or collection access level for a specific user.

=head2 C<create_collection>

   my $col = $database->create_collection("col_name");

Creates a new collection and returns the object representing it (L<Arango::Tango::Collection>).

=head2 C<create_ttl_index>

   $idx = $db->create_ttl_index("col_name", %args);

Creates a new index of type ttl for the given collection. The
mandatory args are C<type> (must be C<ttl>), C<name> (string,
human name for the index), C<fields> (array ref with the
names of the document fields to be used as expiration timestamps)
and C<expireAfter> (integer, seconds).
Returns an object containing the id of the created index and the
confirmation of the provided arguments (C<type>, C<name>, C<fields>
and C<expireAfter>). If an error occurs the error field will be
true, otherwise false.

=head2 C<cursor>

   my $cursor = $database->cursor( $aql_query, %opt );

Performs AQL queries, returning a cursor. An optional hash of
options can be supplied. Supported hashes corresponds to the different attributes
available in the ArangoDB REST API (L<https://docs.arangodb.com/3.4/HTTP/AqlQueryCursor/AccessingCursors.html>).

=head2 C<delete>

    $db->delete;

Deletes the supplied database.

=head2 C<delete_collection>

   $database->delete_collection("col_name");

Deletes a collection.

=head2 C<get_indexes>

   $idxs = $db->get_indexes("col_name");

Returns an object containing an array reference with the details
of the indexes presently defined for the given collection.

=head2 C<list_collections>

   my $cols = $database->list_collections;

Returns an array reference to the collections available in the database.

=head2 C<get_access_level>

    $perms = $db->get_access_level($user)
    $perms = $db->get_access_level($user, $collection)

Fetch the database or collection access level for a specific user.

=head2 C<set_access_level>

    $db->set_access_level($user, "rw")
    $db->set_access_level($user, "ro", $collection)

Set the database or collection access level for a specific user.

=head1 AUTHOR

Alberto Simões <ambs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019-2023 by Alberto Simões.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
