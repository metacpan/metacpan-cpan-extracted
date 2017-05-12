package ArangoDB::Collection;
use strict;
use warnings;
use utf8;
use 5.008001;
use JSON ();
use Carp qw(croak);
use Scalar::Util qw(weaken);
use Class::Accessor::Lite ( ro => [qw/id status/], );
use ArangoDB::Constants qw(:api :status);
use ArangoDB::Document;
use ArangoDB::Edge;
use ArangoDB::Index::Primary;
use ArangoDB::Index::Hash;
use ArangoDB::Index::SkipList;
use ArangoDB::Index::Geo;
use ArangoDB::Index::CapConstraint;
use ArangoDB::Cursor;
use ArangoDB::ClientException;
use overload
    q{""}    => sub { shift->id },
    fallback => 1;

my $JSON = JSON->new->utf8;

=pod

=head1 NAME

ArangoDB::Collection - An ArangoDB collection

=head1 DESCRIPTION

A instance of ArangoDB collection.

=head1 METHODS FOR COLLECTION HANDLING

=head2 new($connection, $collection_info)

Constructor.

=cut

sub new {
    my ( $class, $db, $raw_collection ) = @_;
    my $self = bless { db => $db, connection => $db->{connection}, }, $class;
    weaken( $self->{db} );
    weaken( $self->{connection} );
    for my $key (qw/id name status/) {
        $self->{$key} = $raw_collection->{$key};
    }
    $self->{_api_path} = API_COLLECTION . '/' . $self->{id};
    return $self;
}

=pod

=head2 id()

Returns identifer of the collection.

=head2 status()

Returns status of the collection.

=cut

=pod

=head2 name([$name])

Returns name of collection.
If $name is set, rename the collection.

=cut

sub name {
    my ( $self, $name ) = @_;
    if ($name) {    #rename
        $self->_put_to_this( 'rename', { name => $name } );
        $self->{name} = $name;
    }
    return $self->{name};
}

=pod

=head2 count()

Returns number of documents in the collection.

=cut

sub count {
    my $self = shift;
    my $res  = $self->_get_from_this('count');
    return $res->{count};
}

=pod

=head2 drop()

Drop the collection.

=cut

sub drop {
    my $self = shift;
    my $api  = $self->{_api_path};
    eval { $self->{connection}->http_delete($api); };
    if ($@) {
        $self->_server_error_handler( $@, 'Failed to drop the collection(%s)' );
    }
}

=pod

=head2 truncate()

Truncate the collection.

=cut

sub truncate {
    my $self = shift;
    eval {
        my $res = $self->_put_to_this('truncate');
        $self->{status} = $res->{status};
    };
    if ($@) {
        $self->_server_error_handler( $@, 'Failed to truncate the collection(%s)' );
    }
}

=pod

=head2 load()

Load the collection.

=cut

sub load {
    my $self = shift;
    my $res  = $self->_put_to_this('load');
    $self->{status} = $res->{status};
}

=pod

=head2 unload()

Unload the collection.

=cut

sub unload {
    my $self = shift;
    my $res  = $self->_put_to_this('unload');
    $self->{status} = $res->{status};
}

=pod

=head2 is_newborn()

Return true if status of the collection is 'new born'.

=cut

sub is_newborn {
    $_[0]->{status} == NEWBORN;
}

=pod

=head2 is_unloaded()

Return true if status of the collection is 'unloaded'.

=cut

sub is_unloaded {
    $_[0]->{status} == UNLOADED;
}

=pod

=head2 is_loaded()

Return true if status of the collection is 'loaded'.

=cut

sub is_loaded {
    $_[0]->{status} == LOADED;
}

=pod

=head2 is_being_unloaded()

Return true if status of the collection is 'being unloaded'.

=cut

sub is_being_unloaded {
    $_[0]->{status} == BEING_UNLOADED;
}

=pod

=head2 is_deleted()

Return true if status of the collection is 'deleted'.

=cut

sub is_deleted {
    $_[0]->{status} == DELETED;
}

=pod

=head2 is_corrupted()

Return true if status of the collection is invalid.

=cut

sub is_corrupted {
    return $_[0]->{status} >= CORRUPTED;
}

=pod

=head2 figure($type)

Returns number of documents and additional statistical information about the collection.

$type is key name of figures.The key names are: 

=over 4

=item count

The number of documents inside the collection.

=item alive-count

The number of living documents.

=item alive-size

The total size in bytes used by all living documents.

=item dead-count

The number of dead documents.

=item dead-size

The total size in bytes used by all dead documents.

=item dead-deletion

The total number of deletion markers.

=item datafiles-count

The number of active datafiles.

=item datafiles-fileSize

The total filesize of datafiles.

=item journals-count

The number of journal files.

=item journals-fileSize

The total filesize of journal files.

=item journalSize

The maximal size of the journal in bytes.

=back

=cut

sub figure {
    my ( $self, $type ) = @_;
    my $res = $self->_get_from_this('figures');
    if ( defined $type ) {
        return $res->{count}       if $type eq 'count';
        return $res->{journalSize} if $type eq 'journalSize';
        my ( $area, $name ) = split( '-', $type );
        if ( exists $res->{figures}{$area} ) {
            return $res->{figures}{$area} unless defined $name;
            return $res->{figures}{$area}{$name};
        }
    }
    else {
        return $res->{figures};
    }
    return;
}

=pod

=head2 wait_for_sync($boolean)

Set or get the property 'wait_for_sync' of the collection.

=cut

sub wait_for_sync {
    my $self = shift;
    if ( @_ > 0 ) {
        my $val = $_[0] ? JSON::true : JSON::false;
        my $res = $self->_put_to_this( 'properties', { waitForSync => $val } );
    }
    else {
        my $res = $self->_get_from_this('properties');
        my $ret = $res->{waitForSync} eq 'true' ? 1 : 0;
        return $ret;
    }
}

=pod

=head1 METHODS FOR DOCUMENT HANDLING

=head2 save($data)

Save document to the collection. Returns instance of L<ArangoDB::Document>.

    $collection->save( { name => 'John' } );

=cut

sub save {
    my ( $self, $data ) = @_;
    my $api = API_DOCUMENT . '?collection=' . $self->{id};
    my $doc = eval {
        my $res = $self->{connection}->http_post( $api, $data );
        ArangoDB::Document->new( $self->{connection}, $res )->fetch;
    };
    if ($@) {
        $self->_server_error_handler( $@, 'Failed to save the new document to the collection(%s)' );
    }
    return $doc;
}

=pod

=head2 bulk_import($header,$body)

Import multiple documents at once.

=over 4

=item $header 

attribute names(ARRAY reference).

=item $body  

document values(ARRAY reference).

=back

Example:

    $collection->bulk_import(
        [qw/fistsName lastName age gender/],
        [
            [ "Joe", "Public", 42, "male" ],
            [ "Jane", "Doe", 31, "female" ],
        ]
    );    

=cut

sub bulk_import {
    my ( $self, $header, $body ) = @_;
    croak( ArangoDB::ClientException->new('1st parameter must be ARRAY reference.') )
        unless $header && ref($header) eq 'ARRAY';
    croak( ArangoDB::ClientException->new('2nd parameter must be ARRAY reference.') )
        unless $body && ref($body) eq 'ARRAY';
    my $api  = API_IMPORT . '?collection=' . $self->{id};
    my $data = join "\n", map { $JSON->encode($_) } ( $header, @$body );
    my $res  = eval { $self->{connection}->http_post( $api, $data, 1 ) };
    if ($@) {
        $self->_server_error_handler( $@, 'Failed to bulk import to the collection(%s)' );
    }
    return $res;
}

=pod

=head2 bulk_import_self_contained($documents)

Import multiple self-contained documents at once.

$documents is the ARRAY reference of documents.

Example:

    $collection->bulk_import_self_contained( [ 
        { name => 'foo', age => 20 }, 
        { type => 'bar', count => 100 }, 
    ] );

=cut

sub bulk_import_self_contained {
    my ( $self, $documents ) = @_;
    croak( ArangoDB::ClientException->new('Parameter must be ARRAY reference.') )
        unless $documents && ref($documents) eq 'ARRAY';
    my $api  = API_IMPORT . '?type=documents&collection=' . $self->{id};
    my $data = join "\n", map { $JSON->encode($_) } @$documents;
    my $res  = eval { $self->{connection}->http_post( $api, $data, 1 ) };
    if ($@) {
        $self->_server_error_handler( $@, 'Failed to bulk import to the collection(%s)' );
    }
    return $res;
}

=pod

=head1 METHODS FOR EDGE HANDLING

=head2 save_edge($from,$to[,$data])

Save edge to the collection. Returns instance of L<ArangoDB::Edge>.

=over 4

=item $from

The document that start-point of the edge.

=item $to

The document that end-point of the edge.

=item $data

Document data.

=back

    $collection->save_edge($document1,$document2, { rel => 'has-a' });

=cut

sub save_edge {
    my ( $self, $from, $to, $data ) = @_;
    my $api  = API_EDGE . '?collection=' . $self->{id} . '&from=' . $from . '&to=' . $to;
    my $edge = eval {
        my $res = $self->{connection}->http_post( $api, $data );
        $self->{db}->edge( $res->{_id} );
    };
    if ($@) {
        $self->_server_error_handler( $@, "Failed to save the new edge to the collection(%s)" );
    }
    return $edge;
}

=pod

=head1 METHODS FOR SIMPLE QUERY HANDLING

=head2 all([$options])
 
Send 'all' simple query. Returns instance of L<ArangoDB::Cursor>.

This will return all documents of in the collection.

    my $cursor = $collection->all({ limit => 100 });

$options is query option(HASH reference).The attributes of $options are:

=over 4

=item limit

The maximal amount of documents to return. (optional)

=item skip

The documents to skip in the query. (optional)

=back 

=cut

sub all {
    my ( $self, $options ) = @_;
    $options ||= {};
    my $data = { collection => $self->{id} };
    for my $key ( grep { exists $options->{$_} } qw{limit skip} ) {
        $data->{$key} = $options->{$key};
    }
    my $res = eval { $self->{connection}->http_put( API_SIMPLE_ALL, $data ) };
    if ($@) {
        $self->_server_error_handler( $@, 'Failed to call Simple API(all) for the collection(%s)' );
    }
    return ArangoDB::Cursor->new( $self->{connection}, $res );
}

=pod

=head2 by_example($example[,$options])

Send 'by_example' simple query. Returns instance of L<ArangoDB::Cursor>.

This will find all documents matching a given example.

    my $cursor = $collection->by_example({ age => 20 });

=over 4

=item $example

The exmaple.

=item $options

Query option(HASH reference).The attributes of $options are:

=over 4

=item limit

The maximal amount of documents to return. (optional)

=item skip

The documents to skip in the query. (optional)

=back 

=back

=cut

sub by_example {
    my ( $self, $example, $options ) = @_;
    $options ||= {};
    my $data = { collection => $self->{id}, example => $example };
    map { $data->{$_} = $options->{$_} } grep { exists $options->{$_} } qw(limit skip);
    my $res = eval { $self->{connection}->http_put( API_SIMPLE_EXAMPLE, $data ) };
    if ($@) {
        $self->_server_error_handler( $@, 'Failed to call Simple API(by_example) for the collection(%s)' );
    }
    return ArangoDB::Cursor->new( $self->{connection}, $res );
}

=pod

=head2 first_example($example)

Send 'first_example' simple query. Returns instance of L<ArangoDB::Document>.

This will return the first document matching a given example.

$example is the exmaple.

    my $document = $collection->by_example({ age => 20 });

=cut

sub first_example {
    my ( $self, $example ) = @_;
    my $data = { collection => $self->{id}, example => $example };
    my $res = eval { $self->{connection}->http_put( API_SIMPLE_FIRST, $data ) };
    if ($@) {
        $self->_server_error_handler( $@, 'Failed to call Simple API(first_example) for the collection(%s)' );
    }
    return ArangoDB::Document->new( $self->{connection}, $res->{document} );
}

=pod

=head2 range($attr,$lower,$upper[,$options])

Send 'range' simple query. Returns instance of L<ArangoDB::Cursor>.

It looks for documents in the collection with attribute between two values.

Note: You must declare a skip-list index on the attribute in order to be able to use a range query.

    my $cursor = $collection->range('age', 20, 29, { closed => 1 } );

=over 4

=item $attr 

The attribute path to check.

=item $lower 

The lower bound.

=item $upper 

The upper bound.

=item $options

Query option(HASH reference).The attributes of $options are:

=over 4

=item closed

If true, use intervall including $lower and $upper, otherwise exclude $upper, but include $lower

=item limit

The maximal amount of documents to return. (optional)

=item skip

The documents to skip in the query. (optional)

=back 

=back

=cut

sub range {
    my ( $self, $attr, $lower, $upper, $options ) = @_;
    $options ||= {};
    my $data = { collection => $self->{id}, attribute => $attr, left => $lower, right => $upper, };
    map { $data->{$_} = $options->{$_} } grep { exists $options->{$_} } qw(closed limit skip);
    $data->{closed} = $data->{closed} ? JSON::true : JSON::false;
    my $res = eval { $self->{connection}->http_put( API_SIMPLE_RANGE, $data ) };
    if ($@) {
        $self->_server_error_handler( $@, 'Failed to call Simple API(range) for the collection(%s)' );
    }
    return ArangoDB::Cursor->new( $self->{connection}, $res );
}

=pod

=head2 near($latitude,$longitude[,$options])

Send 'near' simple query. Returns instance of L<ArangoDB::Cursor>.

The default will find at most 100 documents near a given coordinate. 
The returned list is sorted according to the distance, with the nearest document coming first.

    $cursor = $collection->near(0,0, { limit => 20 } );

=over 4

=item $latitude 

The latitude of the coordinate.

=item $longitude 

The longitude of the coordinate.

=item $options 

Query option(HASH reference).The attributes of $options are:

=over 4

=item distance

If given, the attribute key used to store the C<distance> to document(optional).

C<distance> is  the distance between the given point and the document in meter.

=item limit

The maximal amount of documents to return. (optional)

=item skip

The documents to skip in the query. (optional)

=item geo

If given, the identifier of the geo-index to use. (optional)

=back 

=back

=cut

sub near {
    my ( $self, $latitude, $longitude, $options ) = @_;
    $options ||= {};
    my $data = { collection => $self->{id}, latitude => $latitude, longitude => $longitude, };
    map { $data->{$_} = $options->{$_} } grep { exists $options->{$_} } qw(distance limit skip geo);
    my $res = eval { $self->{connection}->http_put( API_SIMPLE_NEAR, $data ) };
    if ($@) {
        $self->_server_error_handler( $@, 'Failed to call Simple API(near) for the collection(%s)' );
    }
    return ArangoDB::Cursor->new( $self->{connection}, $res );
}

=pod

=head2 within($latitude,$longitude,$radius[,$options])

Send 'within' simple query. Returns instance of L<ArangoDB::Cursor>.

This will find all documents with in a given radius around the coordinate (latitude, longitude).
The returned list is sorted by distance.

    $cursor = $collection->within(0,0, 10 * 1000, { distance => 'distance' } );

=over 4

=item $latitude

The latitude of the coordinate.

=item $longitude

The longitude of the coordinate.

=item $radius 

The maximal radius(meter).

=item $options

Query option(HASH reference).The attributes of $options are:

=over 4

=item distance

If given, the attribute name used to store the C<distance> to document(optional).

C<distance> is  the distance between the given point and the document in meter.

=item limit

The maximal amount of documents to return. (optional)

=item skip

The documents to skip in the query. (optional)

=item geo

If given, the identifier of the geo-index to use. (optional)

=back

=back

=cut

sub within {
    my ( $self, $latitude, $longitude, $radius, $options ) = @_;
    $options ||= {};
    my $data = { collection => $self->{id}, latitude => $latitude, longitude => $longitude, radius => $radius, };
    map { $data->{$_} = $options->{$_} }
        grep { exists $options->{$_} } qw(distance limit skip geo);
    my $res = eval { $self->{connection}->http_put( API_SIMPLE_WITHIN, $data ) };
    if ($@) {
        $self->_server_error_handler( $@, 'Failed to call Simple API(within) for the collection(%s)' );
    }
    return ArangoDB::Cursor->new( $self->{connection}, $res );
}

=pod

=head1 METHODS FOR INDEX HANDLING

=head2 ensure_hash_index($fileds)

Create hash index for the collection. Returns instance of L<ArangoDB::Index::Hash>.

This hash is then used in queries to locate documents in O(1) operations. 

$fileds is the field of index.

    $collection->ensure_hash_index([qw/user.name/]);
    $collection->save({ user => { name => 'John', age => 42,  } });

=cut

sub ensure_hash_index {
    my ( $self, $fields ) = @_;
    my $api  = API_INDEX . '?collection=' . $self->{id};
    my $data = { type => 'hash', unique => JSON::false, fields => $fields, };
    my $res  = eval { $self->{connection}->http_post( $api, $data ) };
    if ($@) {
        $self->_server_error_handler( $@, 'Failed to create hash index on the collection(%s)' );
    }
    return ArangoDB::Index::Hash->new( $self->{connection}, $res );
}

=pod

=head2 ensure_unique_constraint($fileds)

Create unique hash index for the collection. Returns instance of L<ArangoDB::Index::Hash>.

This hash is then used in queries to locate documents in O(1) operations. 
If using unique hash index then no two documents are allowed to have the same set of attribute values.

$fileds is the field of index.

=cut

sub ensure_unique_constraint {
    my ( $self, $fields ) = @_;
    my $api  = API_INDEX . '?collection=' . $self->{id};
    my $data = { type => 'hash', unique => JSON::true, fields => $fields, };
    my $res  = eval { $self->{connection}->http_post( $api, $data ) };
    if ($@) {
        $self->_server_error_handler( $@, 'Failed to create unique hash index on the collection(%s)' );
    }
    return ArangoDB::Index::Hash->new( $self->{connection}, $res );
}

=pod

=head2 ensure_skiplist($fileds)

Create skip-list index for the collection. Returns instance of L<ArangoDB::Index::SkipList>.

This skip-list is then used in queries to locate documents within a given range. 

$fileds is the field of index.

    $collection->ensure_skiplist([qw/user.age/]);
    $collection->save({ user => { name => 'John', age => 42 } });

=cut

sub ensure_skiplist {
    my ( $self, $fields ) = @_;
    my $api  = API_INDEX . '?collection=' . $self->{id};
    my $data = { type => 'skiplist', unique => JSON::false, fields => $fields, };
    my $res  = eval { $self->{connection}->http_post( $api, $data ) };
    if ($@) {
        $self->_server_error_handler( $@, 'Failed to create skiplist index on the collection(%s)' );
    }
    return ArangoDB::Index::SkipList->new( $self->{connection}, $res );
}

=pod

=head2 ensure_unique_skiplist($fileds)

Create unique skip-list index for the collection. Returns instance of L<ArangoDB::Index::SkipList>.

This skip-list is then used in queries to locate documents within a given range. 
If using unique skip-list then no two documents are allowed to have the same set of attribute values.

$fileds is the field of index.

=cut

sub ensure_unique_skiplist {
    my ( $self, $fields, $unique ) = @_;
    my $api  = API_INDEX . '?collection=' . $self->{id};
    my $data = { type => 'skiplist', unique => JSON::true, fields => $fields, };
    my $res  = eval { $self->{connection}->http_post( $api, $data ) };
    if ($@) {
        $self->_server_error_handler( $@, 'Failed to create unique skiplist index on the collection(%s)' );
    }
    return ArangoDB::Index::SkipList->new( $self->{connection}, $res );
}

=pod

=head2 ensure_geo_index($fileds[,$is_geojson])

Create geo index for the collection. Returns instance of L<ArangoDB::Index::Geo>.

=over 4

=item $fileds

The field of index.

=item $is_geojson 

Boolean flag. If it is true, then the order within the list is longitude followed by latitude. 

=back

Create an geo index for a list attribute:

    $collection->ensure_geo_index( [qw/loc/] );
    $collection->save({ loc => [0 ,0] });

Create an geo index for a hash array attribute:

    $collection->ensure_geo_index( [qw/location.latitude location.longitude/] );
    $collection->save({ location => { latitude => 0, longitude => 0 } }); 

=cut

sub ensure_geo_index {
    my ( $self, $fields, $is_geojson ) = @_;
    my $api  = API_INDEX . '?collection=' . $self->{id};
    my $data = {
        type       => 'geo',
        fields     => $fields,
        constraint => JSON::false,
        geoJson    => $is_geojson ? JSON::true : JSON::false,
    };
    my $res = eval { $self->{connection}->http_post( $api, $data ) };
    if ($@) {
        $self->_server_error_handler( $@, 'Failed to create geo index on the collection(%s)' );
    }
    return ArangoDB::Index::Geo->new( $self->{connection}, $res );
}

=pod

=head2 ensure_geo_constraint($fileds[,$ignore_null])

It works like ensure_geo_index() but requires that the documents contain a valid geo definition.
Returns instance of L<ArangoDB::Index::Geo>.

=over 4

=item $fileds

The field of index.

=item $ignore_null

Boolean flag. If it is true, then documents with a null in location or at least one null in latitude or longitude are ignored.

=back

=cut

sub ensure_geo_constraint {
    my ( $self, $fields, $ignore_null ) = @_;
    my $api  = API_INDEX . '?collection=' . $self->{id};
    my $data = {
        type       => 'geo',
        fields     => $fields,
        constraint => JSON::true,
        ignoreNull => $ignore_null ? JSON::true : JSON::false,
    };
    my $res = eval { $self->{connection}->http_post( $api, $data ) };
    if ($@) {
        $self->_server_error_handler( $@, 'Failed to create geo constraint on the collection(%s)' );
    }
    return ArangoDB::Index::Geo->new( $self->{connection}, $res );
}

=pod

=head2 ensure_cap_constraint($size)

Create cap constraint for the collection.Returns instance of L<ArangoDB::Index::CapConstraint>.

It is possible to restrict the size of collection.

$size is the maximal number of documents.

Restrict the number of document to at most 100 documents:

    $collection->ensure_cap_constraint(100);

=cut

sub ensure_cap_constraint {
    my ( $self, $size ) = @_;
    my $api  = API_INDEX . '?collection=' . $self->{id};
    my $data = { type => 'cap', size => $size, };
    my $res  = eval { $self->{connection}->http_post( $api, $data ) };
    if ($@) {
        $self->_server_error_handler( $@, 'Failed to create cap constraint on the collection(%s)' );
    }
    return ArangoDB::Index::CapConstraint->new( $self->{connection}, $res );
}

=pod

=head2 get_indexes()

Returns list of indexes of the collection.

=cut

sub get_indexes {
    my $self    = shift;
    my $api     = API_INDEX . '?collection=' . $self->{id};
    my @indexes = eval {
        my $res = $self->{connection}->http_get($api);
        map { $self->_get_index_instance($_) } @{ $res->{indexes} };
    };
    if ($@) {
        $self->_server_error_handler( $@, 'Failed to get the index($index_id) on the collection(%s)' );
    }
    return \@indexes;
}

# Get property of the collection.
sub _get_from_this {
    my ( $self, $path ) = @_;
    my $api = $self->{_api_path} . '/' . $path;
    my $res = eval { $self->{connection}->http_get($api) };
    if ($@) {
        $self->_server_error_handler( $@, "Failed to get the property($path) of the collection(%s)" );
    }
    return $res;
}

# Set property of the collection.
sub _put_to_this {
    my ( $self, $path, $params ) = @_;
    my $api = $self->{_api_path} . '/' . $path;
    my $res = eval { $self->{connection}->http_put( $api, $params ) };
    if ($@) {
        $self->_server_error_handler( $@, "Failed to update the property($path) of the collection(%s)" );
    }
    return $res;
}

# get instance of index
sub _get_index_instance {
    my ( $self, $index ) = @_;
    my $type = $index->{type} || q{};
    my $conn = $self->{connection};
    if ( $type eq 'primary' ) {
        return ArangoDB::Index::Primary->new( $conn, $index );
    }
    elsif ( $type eq 'hash' ) {
        return ArangoDB::Index::Hash->new( $conn, $index );
    }
    elsif ( $type eq 'skiplist' ) {
        return ArangoDB::Index::SkipList->new( $conn, $index );
    }
    elsif ( $type eq 'cap' ) {
        return ArangoDB::Index::CapConstraint->new( $conn, $index );
    }
    elsif ( $type =~ /^geo[12]$/ ) {
        return ArangoDB::Index::Geo->new( $conn, $index );
    }
    else {
        croak(
            ArangoDB::ServerException->new(
                { code => 500, status => '', detail => { errorMessage => "Unknown index type($type)", } }
            )
        );
    }
}

# Handling server error
sub _server_error_handler {
    my ( $self, $error, $message ) = @_;
    my $msg = sprintf( $message, $self->{name} );
    if ( ref($error) && $error->isa('ArangoDB::ServerException') ) {
        $msg .= ':' . ( $error->detail->{errorMessage} || q{} );
    }
    croak $msg;
}

1;
__END__

=pod

=head1 AUTHOR

Hideaki Ohno E<lt>hide.o.j55 {at} gmail.comE<gt>

=cut
