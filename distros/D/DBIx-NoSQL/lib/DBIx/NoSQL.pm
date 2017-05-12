package DBIx::NoSQL;
our $AUTHORITY = 'cpan:YANICK';
$DBIx::NoSQL::VERSION = '0.0021';
# ABSTRACT: NoSQL-ish overlay for an SQL database

use strict;
use warnings;

use DBIx::NoSQL::Store;

sub new {
    my $class = shift;
    return DBIx::NoSQL::Store->new( @_ );
}

sub connect {
    my $class = shift;
    return DBIx::NoSQL::Store->connect( @_ );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::NoSQL - NoSQL-ish overlay for an SQL database

=head1 VERSION

version 0.0021

=head1 SYNOPSIS

    use DBIx::NoSQL;

    my $store = DBIx::NoSQL->connect( 'store.sqlite' );

    $store->set( 'Artist' => 'Smashing Pumpkins' => {
        name => 'Smashing Pumpkins',
        genre => 'rock',
        website => 'smashingpumpkins.com',
    } );

    $store->exists( 'Artist' => 'Smashing Pumpkins' ); # 1

    $store->set( 'Artist' => 'Tool' => {
        name => 'Tool',
        genre => 'rock',
    } );

    $store->search( 'Artist' )->count; # 2

    my $artist = $store->get( 'Artist' => 'Smashing Pumpkins' );

    # Set up a (searchable) index on the name field
    $store->model( 'Artist' )->index( 'name' );
    $store->model( 'Artist' )->reindex;

    for $artist ( $store->search( 'Artist' )->order_by( 'name DESC' )->all ) {
        ...
    }

    $store->model( 'Album' )->index( 'released' => ( isa => 'DateTime' ) );

    $store->set( 'Album' => 'Siamese Dream' => {
        artist => 'Smashing Pumpkins',
        released => DateTime->new( ... ),
    } );

    my $album = $store->get( 'Album' => 'Siamese Dream' );
    my $released = $album->{ released }; # The field is automatically inflated
    print $release->strftime( ... );

=head1 DESCRIPTION

DBIx::NoSQL is a layer over DBI that presents a NoSQLish way to store and retrieve data. It does this by using a table called C<__Store__>. Once connected to a database, it will detect if this table is missing and create it if necessary

When writing data to the store, the data (a HASH reference) is first serialized using L<JSON> and then inserted/updated via L<DBIx::Class> to (currently) an SQLite backend

Retrieving data from the store is done by key lookup or by searching an SQL-based index. Once found, the data is deserialized via L<JSON> and returned

The API is fairly sane, though still beta

=head1 USAGE

=head2 $store = DBIx::NoSQL->connect( $path )

Returns a new DBIx::NoSQL store connected to the SQLite database located at C<$path>

If the SQLite database file at C<$path> does not exist, it will be created

=head2 $store->set( $model, $key, $value )

Set C<$key> (a string) to C<$value> (a HASH reference) in C<$model>

If C<$model> has index, this command will also update the index entry corresponding to C<$key>.

The C<$key> can be omitted, in which case a UUID key will be auto-generated for the entry.

Returns the new entry's key.

=head2 $value = $store->exists( $model, $key )

Returns true if some data for C<$key> is present in C<$model>

=head2 $value = $store->get( $model, $key )

Get C<$value> matching C<$key> in C<$model>

=head2 $value = $store->delete( $model, $key )

Delete the entry matching C<$key> in C<$model>

If C<$model> has index, this command will also delete the index entry corresponding to C<$key>

=head2 $store->reindex

Reindex the searchable/orderable data in C<$store>

This method is smart, in that it won't reindex a model unless the schema for $store is different/has changed. That is, if the schema for C<$store> is the same as it is in the database, this call will do nothing

Refer to "Model USAGE" below for more information

=head2 $store->dbh

Return the L<DBI> database handle for the store, if you need/want to do your own thing

=head1 Search USAGE

To search on a model, you must have installed an index on the field you want to search on

Refer to "Model USAGE" for indexing information

=head2 $search = $store->search( $model, [ $where ] )

    $search = $store->search( 'Artist' => { name => { -like => 'Smashing%' } } )

Return a L<DBIx::NoSQL::Search> object for C<$model>, filtering on the optional C<$where>

An index is required for the filtering columns

Refer to L<SQL::Abstract> for the format of C<$where> (actually uses L<DBIx::Class::SQLMaker> under the hood)

=head2 @all = $search->all

Returns every result for C<$search> in a list

Returns an empty list if nothing is found

=head2 $result = $search->next

Returns the next item found for C<$search> via C<< $search->cursor >>

Returns undef if nothing is left for C<$search> 

=head2 $sth = $search->cursor->sth

Returns the L<DBI> sth (statement handle) for C<$search>

=head2 $search = $search->search( $where )

Further refine the search in the same way C<< $search->where( ... ) >> does

=head2 $search = $search->where( $where )

    $search = $search->where( { genre => 'rock' } ) 

Further refine C<$search> with the given C<$where>

A new object is cloned from the original (the original C<$search> is left untouched)

An index is required for the filtering columns

Refer to L<SQL::Abstract> for the format of C<$where> (actually uses L<DBIx::Class::SQLMaker> under the hood)

=head2 $search = $search->order_by( $order_by )

    $search->order_by( 'name DESC' )

    $search->order_by([ 'name DESC', 'age' ])

Return the results in the given order

A new object is cloned from the original, which is left untouched

An index is required for the ordering columns

Refer to L<SQL::Abstract> for the format of C<$order_by> (actually uses L<DBIx::Class::SQLMaker> under the hood)

=head1 Model USAGE

=head2 $model = $store->model( $model_name )

Retrieve or create the C<$model_name> model object

=head2 $model->index( $field_name )

    $store->model( 'Artist' )->index( 'name' ) # 'name' is now searchable/orderable, etc.

Index C<$field_name> on C<$model>

Every time the store for c<$model> is written to, the index will be updated with the value of C<$field>

=head2 $model->index( $field_name, isa => $type )

    $store->model( 'Artist' )->index( 'website', isa => 'URI' )
    $store->model( 'Artist' )->index( 'founded', isa => 'DateTime' )

Index C<$field_name> on C<$model> as a special type/object (e.g. L<DateTime> or L<URI>)

Every time the store for c<$model> is written to, the index will be updated with the deflated value of C<$field> (since
L<JSON> can not trivially serialize blessed references)

=head2 $model->reindex

Reindex the C<$model> data in the store after making a field indexing change:

    1. Rebuild the DBIx::Class::ResultSource
    2. Drop and recreate the search table for $model
    3. Iterate through all the data for $model, repopulating the search table

If C<$model> does not have an index, this method will simply return

To rebuild the index for _every_ model (on startup, for example), you can do:

    $store->reindex

=head1 In the future

Create a better interface for stashing and document it

Wrap things in transactions that need it

More tests: Always. Be. Testing.

=head1 SEE ALSO

L<KiokuDB>

L<DBIx::Class>

L<DBD::SQLite>

=head1 AUTHORS

=over 4

=item *

Robert Krimen <robertkrimen@gmail.com>

=item *

Yanick Champoux <yanick@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Robert Krimen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
