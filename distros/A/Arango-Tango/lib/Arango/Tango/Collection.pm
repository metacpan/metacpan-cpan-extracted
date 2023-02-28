# ABSTRACT: ArangoDB Collection object
package Arango::Tango::Collection;
$Arango::Tango::Collection::VERSION = '0.019';
use warnings;
use strict;

use Arango::Tango::API;

BEGIN {
    Arango::Tango::API::_install_methods "Arango::Tango::Collection" => {

        ## Document Management -- Keeping here for now.
        delete_document => {
            rest => [ delete => '{{database}}_api/document/{name}/{key}'],
            inject_properties => ['database', 'name'],
            signature => ['key'],
            ## FIXME - Header parameters still not supported
            ## FIXME: missing schema options
        },

        document => {
            rest => [ get => '{{database}}_api/document/{name}/{key}' ],
            inject_properties => [ 'database', 'name' ],
            signature => ['key'],
            ## FIXME - Header parameters still not supported
        },

        ## Collection Management
        load_indexes => {
            rest => [ put => '{{database}}_api/collection/{name}/loadIndexesIntoMemory' ],
            inject_properties => [ 'database', 'name' ],
        },

        rename => {
            rest => [ put => '{{database}}_api/collection/{collection}/rename' ],
            inject_properties => [ 'database', { prop => 'name', as => 'collection'  } ],
            signature => [ 'name' ],
            schema => { name => { type => 'string' }},
        },

        properties => {
            rest => [ get => '{{database}}_api/collection/{name}/properties' ],
            inject_properties => ['database', 'name' ],
        },

        truncate => {
            rest => [ put => '{{database}}_api/collection/{name}/truncate' ],
            inject_properties => [ 'database', 'name' ]
        },

        revision => {
            rest => [ get => '{{database}}_api/collection/{name}/revision' ],
            inject_properties => [ 'database', 'name' ],
        },

        info => {
            rest => [ get => '{{database}}_api/collection/{name}' ],
            inject_properties => [ 'database', 'name' ],
        },

        recalculate_count => {
            rest => [ put => '{{database}}_api/collection/{name}/recalculateCount' ],
            inject_properties => [ 'database', 'name' ],
        },

        rotate => {
            rest => [ put => '{{database}}_api/collection/{name}/rotate' ],
            inject_properties => [ 'database', 'name' ],
        },

        figures => {
            rest => [ get => '{{database}}_api/collection/{name}/figures' ],
            schema => { withRevisions => { type => 'boolean' }, withData => {type=>'boolean' }},
            inject_properties => [ 'database', 'name' ],
        },

        count => {
            rest => [ get => '{{database}}_api/collection/{name}/count' ],
            schema => { withRevisions => { type => 'boolean' }, withData => {type=>'boolean' }},
            inject_properties => [ 'database', 'name' ],
        },


        checksum => {
            rest => [ get => '{{database}}_api/collection/{name}/checksum' ],
            schema => { withRevisions => { type => 'boolean' }, withData => {type=>'boolean' }},
            inject_properties => [ 'database', 'name' ],
        },

        set_properties => {
            rest => [ put => '{{database}}_api/collection/{name}/properties'],
            schema => {  waitForSync => { type => 'boolean' }, journalSize => { type => 'integer' }},
            inject_properties => [ 'database', 'name' ],
        },

    };
}



sub _new {
    my ($class, %opts) = @_;
    return bless {%opts} => $class;
}

sub bulk_import {
    my ($self, $documents, %options) = @_;
    $options{type} ||= "list";
    return $self->{arango}->_api( bulk_import_list => {
        database => $self->{database},
        collection => $self->{name},
        _body => $documents,
        _url_parameters => \%options
    })
}

sub document_paths {              ## FIXME: try to get larger cursors whenever possible
    my ($self) = @_;
    my $paths = [];
    my $query = qq!FOR doc IN $self->{name} RETURN CONCAT("/_db/", CURRENT_DATABASE(), "/_api/document/", doc._id)!;
    my $cursor = $self->cursor($query);
    while(my $row = $cursor->next) {
        push @$paths, @$row;
    }
    return $paths;
}

sub create_document {
    my ($self, $body) = @_;
    die "Arango::Tango | Refusing to store undefined body" unless defined($body);
    return $self->{arango}->_api( create_document => { database => $self->{database}, collection => $self->{name}, _body => $body})
}

sub replace_document {
    my ($self, $key, $body) = @_;
    die "Arango::Tango | Refusing to store undefined body" unless defined($body);
    return $self->{arango}->_api( replace_document => { database => $self->{database}, collection => $self->{name}, key => $key, _body => $body})
}

sub get_access_level {
    my ($self, $username) = @_;
    return $self->{arango}->get_access_level( $username, $self->{database}, $self->{name} );
}

sub clear_access_level {
    my ($self, $username) = @_;
    return $self->{arango}->clear_access_level( $username , $self->{database}, $self->{name} );
}

sub set_access_level {
    my ($self, $username, $grant) = @_;
    return $self->{arango}->set_access_level($username, $grant, $self->{database}, $self->{name});
}

sub cursor {
    my ($self, $aql, %opts) = @_;
    return Arango::Tango::Cursor->_new(arango => $self->{arango}, database => $self->{database}, query => $aql, %opts);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Arango::Tango::Collection - ArangoDB Collection object

=head1 VERSION

version 0.019

=head1 USAGE

This class should not be created directly. The L<Arango::Tango> module is responsible for
creating instances of this object.

C<Arango::Tango::Collection> answers to the following methods:

=head2 C<load_indexes>

   $ans = $collection->load_indexes;

This route tries to cache all index entries of this collection into
the main memory.  Therefore it iterates over all indexes of the
collection and stores the indexed values, not the entire document
data, in memory.

=head2 C<info>

   $info = $collection->info;

The result is an object describing the collection.

=head2 C<checksum>

   $data = $collection->checksum;

Will calculate a checksum of the meta-data (keys and optionally revision ids) and
optionally the document data in the collection.

=head2 C<count>

   $n = $collection->count;

In addition to the above C<checksum>, the result also contains the number of documents.

=head2 C<document>

   $doc = $collection->document("doc_key");

Retrieves a document given a specific key. The header options are not supported yet.

=head2 C<figures>

   $figures = $collection->figures;

In addition to the above (C<count>), the result also contains the number of documents
and additional statistical information about the collection.

=head2 C<properties>

   $properties = $collection->properties;

In addition to the above, the result will always contain the
waitForSync attribute, and the doCompact, journalSize,
and isVolatile attributes for the MMFiles storage engine.

=head2 C<set_properties>

   $properties = $collection->set_properties( waitForSync => 1 );

Changes the properties of a collection.

=head2 C<revision>

   $rev = $collection->revision;

In addition to the above, the result will also contain the
collection’s revision id. The revision id is a server-generated
string that clients can use to check whether data in a collection
has changed since the last revision check.

=head2 C<create_document>

   $collection->create_document( { 'Hello' => 'World' } );
   $collection->create_document( q!"{ "Hello": "World" }! );

Stores a document in specified collection

=head2 C<replace_document>

   $collection->replace_document( $key,  { 'Hello' => 'World' } );

Replaces a document in specified collection

=head2 C<delete_document>

   $collection->delete_document($key);

Deletes a document in specified collection

=head2 C<truncate>

   $collection->truncate;

Removes all documents from the collection, but leaves the indexes intact.

=head2 C<rotate>

   $status = $collection->rotate;

Rotates the journal of a collection. The current journal of the collection will be closed
and made a read-only datafile. The purpose of the rotate method is to make the data in
the file available for compaction (compaction is only performed for read-only datafiles, and
not for journals).

B<Note:> this method is specific for the MMFiles storage engine, and
there it is not available in a cluster.

=head2 C<rename>

   my $ans = $collection->rename("newName");

Renames a collection.

=head2 C<recalculate_count>

   my $ans = $collection->recalculate_count;

Recalculates the document count of a collection, if it ever becomes inconsistent.

B<Note:> this method is specific for the RocksDB storage engine.

=head2 C<document_paths>

   my $paths = $collection->document_paths;

Lists all collection document as their paths in the database. Returns a hash reference.

=head2 C<get_access_level>

    my $perms = $db->get_access_level($user)

Fetch the collection access level for a specific user.

=head2 C<set_access_level>

    $db->set_access_level($user, 'none')

Sets the collection access level for a specific user.

=head2 C<clear_access_level>

    $db->clear_access_level($user, 'none')

Clears the collection access level for a specific user.

=head2 C<bulk_import>

    $collection->bulk_import([{_key => "something"}, {_key => "something else"}])

Imports a group of documents in a single call.

=head2 C<cursor>

   my $cursor = $collection->cursor( $aql_query, %opt );

Performs AQL queries, returning a cursor. An optional hash of
options can be supplied. Supported hashes corresponds to the different attributes
available in the ArangoDB REST API (L<https://docs.arangodb.com/3.4/HTTP/AqlQueryCursor/AccessingCursors.html>).

=head1 AUTHOR

Alberto Simões <ambs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019-2023 by Alberto Simões.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
