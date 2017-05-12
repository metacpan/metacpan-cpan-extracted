=head1 NAME

DBIx::SQLEngine::Record::Cache - Avoid Repeated Selects

=head1 SYNOPSIS

B<Setup:> Several ways to create a class.

  my $sqldb = DBIx::SQLEngine->new( ... );

  $class_name = $sqldb->record_class( $table_name, undef, 'Cache' );
  
  $sqldb->record_class( $table_name, 'My::Record', 'Cache' );
  
  package My::Record;
  use DBIx::SQLEngine::Record::Class '-isasubclass', 'Cache';  
  My::Record->table( $sqldb->table($table_name) );

B<Cache:> Uses Cache::Cache interface.

  $class_name->use_cache_style('simple');

  # requires Cache::FastMemoryCache
  $class_name->use_cache_style('active'); 

  use Cache::Cache;
  $class_name->cache_cache( $my_cache_cache_object );

B<Basics:> Layered over superclass.

  # Fetches from cache if it's been seen before
  $record = $class_name->fetch_record( $primary_key );

  # Fetches from cache if we've run this query before
  @records = $class_name->fetch_select(%clauses)->records;
  
  # Clears cache so it's seen by next select query
  $record->insert_record();
  
  # Clears cache so it's seen by next select query
  $record->update_record();
  
  # Clears cache so it's seen by next select query
  $record->delete_record();


=head1 DESCRIPTION

This package provides a caching layer for DBIx::SQLEngine::Record objects.

Don't use this module directly; instead, pass its name as a trait when you create a new record class. This package provides a multiply-composable collection of functionality for Record classes. It is combined with the base class and other traits by DBIx::SQLEngine::Record::Class. 

=cut

########################################################################

package DBIx::SQLEngine::Record::Cache;

use strict;
use Carp;

use Storable 'freeze';

########################################################################

########################################################################

=head1 CACHE INTERFACE

=cut

########################################################################

=head2 Cache Configuration

=over 4

=item cache_cache()

  $record_class->cache_cache() : $cache_cache
  $record_class->cache_cache( $cache_cache ) 

Gets or sets the cache object associated with this record class.

If no cache has been set for a given class, no caching is performed.

=back

B<Cache Object Requirements:> This package in intended to work with cache object that use the Cache::Cache interface. However, any package which support the limited cache interface used by this package should be sufficient. 

Two small classes are included that support this interface; see L<DBIx::SQLEngine::Cache::TrivialCache> and  L<DBIx::SQLEngine::Cache::BasicCache>.

The following methods are used

=over 4

Constructor.

=item get_namespace()

Used to differentiate one cache object from another.

=item get()

Fetch a value from the cache, if it is present.

=item set()

Set a value in the cache.

=item clear()

Clear some or all values in the cache.

=back

=cut

use Class::MakeMethods (
  'Template::ClassInherit:scalar' => 'cache_cache',
);

########################################################################

=head2 Cache Operations

=over 4

=item cache_key()

  $record_class->cache_key( $key ) : $string_value
  $record_class->cache_key( \@key ) : $string_value
  $record_class->cache_key( \%key ) : $string_value

Returns the string value to be used as a cache key. The argument may be an existing string, a reference to a shallow array whose elements will be joined with "\0/\0", or any other reference value which will be stringified by Storable.

=item cache_get()

  $record_class->cache_get( $key ) : $value
  $record_class->cache_get( $key ) : ( $value, $updater_code_ref )

Returns the cached value associated with this key, if any. If called in a list context, also returns a reference to a subroutine which will save a new value for that key.

=item cache_set()

  $record_class->cache_set( $key, $value )

Caches this value under the provided key.

=item cache_get_set()

  $record_class->cache_get_set( $key, $code_ref, @args ) : $value

Returns the curent value provided by a cache_get on the provided key, or if it is undefined, invokes the subroutine reference with any additional arguments provided, and saves the subroutine's return value as the cached value.

=item cache_clear()

  $record_class->cache_clear()
  $record_class->cache_clear( $key )

Clear all values from the cache, or just those associated with the given key.

=back

=cut

sub cache_key {
  my ( $self, $key ) = @_;
  my $type = ref($key);
  if ( ! $type ) { 
    $key 
  } elsif ( $type eq 'ARRAY' ) {
    join("\0/\0", @$key) 
  } else { 
    local $Storable::canonical = 1; 
    freeze($key) 
  }
}

# $value = $self->cache_get( $key );
# ( $value, $update ) = $self->cache_get( $key );
sub cache_get {
  my ( $self, $key ) = @_;
  
  my $cache = $self->cache_cache() or return;
  
  $key = $self->cache_key($key) if ( ref $key );
  my $current = $cache->get( $key );
  
  if ( ! defined $current ) {
    $self->cache_log_operation( $cache, 'miss', $key );
  } else {
    $self->cache_log_operation( $cache, 'hit', $key );
  } 
  
  ! wantarray ? $current : ( $current, sub { 
    $self->cache_log_operation( $cache, 'update', $key );
    $cache->set( $key, @_ );
  } );
}

# $self->cache_set( $key, $value );
sub cache_set {
  my ( $self, $key, @value ) = @_;
  
  my $cache = $self->cache_cache() or return;
  
  $key = $self->cache_key($key) if ( ref $key );
  
  $self->cache_log_operation( $cache, 'write', $key );
  $cache->set( $key, @value );
}

# $value = $self->cache_get_set( $key, \&sub, @args );
sub cache_get_set {
  my ( $self, $key, $sub, @args ) = @_;
  
  my ($current, $update) = $self->cache_get($key);
  
  if ( ! defined $current ) {
    $current = &$sub( @args );
    &$update( defined($current) ? $current : '' );
  }
  
  $current;
}

# $self->cache_clear();
# $self->cache_clear( $key );
sub cache_clear {
  my ( $self, $key ) = @_;
  
  my $cache = $self->cache_cache() or return;

  if ( ! $key ) {
    $self->cache_log_operation( $cache, 'clear' );
    $cache->clear();
  } else {
    $self->cache_log_operation( $cache, 'clear', $key );
    $cache->set($key, undef);
  }
}

########################################################################

=head2 Cache Logging

=over 4

=item CacheLogging()

  $record_class->CacheLogging() : $level
  $record_class->CacheLogging( $level )

Sets the logging level associated with a given class. 

=item cache_log_operation()

  $record_class->cache_log_operation( $cache, $operation, $key ) 

Does nothing unless a CacheLogging level is set for this class.

Uses warn() to print a message to the error log, including the key string used, and the operation, which will be one of "hit", "miss", "write", and "clear".

If the level is greater than one, the message will also include a history of prior operations on this key.

=back

=cut

use Class::MakeMethods (
  'Template::ClassInherit:scalar' => 'CacheLogging',
);

use vars qw( %CachingHistory );

sub cache_log_operation {
  my ( $self, $cache, $oper, $key ) = @_;
  my $level = $self->CacheLogging() or return;
  my $namespace = $cache->get_namespace;
  if ( $level > 1 ) {
    my $history = ( $CachingHistory{ $key } ||= [] );
    $oper .= " (" . join(' ', @$history ) . ")";
    push @$history, $oper;
  }
  warn "Cache $namespace: $oper " . DBIx::SQLEngine::printable($key) . "\n";
} 

########################################################################

=head2 Cache Styles

=over 4

=item define_cache_styles()

  DBIx::SQLEngine->define_cache_styles( $name, $code_ref )
  DBIx::SQLEngine->define_cache_styles( %names_and_code_refs )

Define a named caching style. The code ref supplied for each name should create and return an object from the Cache::Cache hierarchy, or another caching class which supports the interface described in the "Cache Object Requirements" section above.

=item cache_styles()

  DBIx::SQLEngine->cache_styles() : %names_and_info
  DBIx::SQLEngine->cache_styles( $name ) : $info
  DBIx::SQLEngine->cache_styles( \@names ) : @info
  DBIx::SQLEngine->cache_styles( $name, $info, ... )
  DBIx::SQLEngine->cache_styles( \%names_and_info )

Accessor for global hash mapping cache names to initialization subroutines.

=item use_cache_style()

  $class_name->use_cache_style( $cache_style_name )
  $class_name->use_cache_style( $cache_style_name, @options )

Uses the named caching definition to create a new cache object, and associates it with the given class.

Use one of the predefined caching styles described in the "Default Caching Styles" section below, or define your own cache styles with define_cache_styles.

=back

=cut

use Class::MakeMethods (
  'Standard::Global:hash' => 'cache_styles',
);

sub define_cache_styles {
  my $self = shift;
  $self->cache_styles( @_ );
}

sub use_cache_style {
  my ( $class, $style, %options ) = @_;
  my $sub = $class->cache_styles( $style );
  my $cache = $sub->( $class, %options );
  $class->cache_cache( $cache );
}

########################################################################

=pod

B<Default Caching Styles:> The following cache styles are predefined. Except for 'simple', using any of these styles will require installation of the Cache::Cache distribution.

=over 4

=item 'simple'

Uses DBIx::SQLEngine::Cache::TrivialCache.

=item 'live'

Uses Cache::FastMemoryCache with a default expiration time of 1 seconds.

=item 'active'

Uses Cache::FastMemoryCache with a default expiration time of 5 seconds.

=item 'stable'

Uses Cache::FastMemoryCache with a default expiration time of 30 seconds.

=item 'file'

Uses Cache::FileCache with a default expiration time of 30 seconds.

=back

B<Examples:>

=over 2

=item *

  # requires DBIx::SQLEngine::Cache::TrivialCache
  $class_name->use_cache_style('simple');

=item *

  # requires Cache::FastMemoryCache from CPAN
  $class_name->use_cache_style('active'); 

=back

=cut

__PACKAGE__->define_cache_styles( 
  'simple' => sub {
    require DBIx::SQLEngine::Cache::TrivialCache;
    DBIx::SQLEngine::Cache::TrivialCache->new();
  },
  'live' => sub {
    require Cache::FastMemoryCache;
    Cache::FastMemoryCache->new( { 
      'namespace' => 'RecordCache:' . (shift), 
      'default_expires_in'  => 1,
      'auto_purge_interval' => 10,
      @_
    } )
  },
  'active' => sub {
    require Cache::FastMemoryCache;
    Cache::FastMemoryCache->new( { 
      'namespace' => 'RecordCache:' . (shift), 
      'default_expires_in'  => 5,
      'auto_purge_interval' => 60,
      @_
    } )
  },
  'stable' => sub {
    require Cache::FastMemoryCache;
    Cache::FastMemoryCache->new( { 
      'namespace' => 'RecordCache:' . (shift), 
      'default_expires_in'  => 30,
      'auto_purge_interval' => 60,
      @_
    } )
  },
  'file' => sub {
    require Cache::FileCache;
    Cache::FileCache->new( { 
      'namespace' => 'RecordCache:' . (shift), 
      'default_expires_in'  => 30,
      'auto_purge_interval' => 60,
      @_
    } )
  },
);

########################################################################

########################################################################

=head1 FETCHING DATA (SQL DQL)

Each of these methods provides a cached version of the superclass method. 
The results of queries are cached based on the SQL statement and parameters used. 

=over 4

=item fetch_select()

  $class_name->fetch_select( %select_clauses ) : $record_set

Retrives records from the table using the provided SQL select clauses. 

=item fetch_one_record()

  $sqldb->fetch_one_record( %select_clauses ) : $record_hash

Retrives one record from the table using the provided SQL select clauses. 

=item select_record()

  $class_name->select_record ( $primary_key_value ) : $record_obj
  $class_name->select_record ( \@compound_primary_key ) : $record_obj
  $class_name->select_record ( \%hash_with_primary_key_value ) : $record_obj

Fetches a single record by primary key.

=item select_records()

  $class_name->select_records ( @primary_key_values_or_hashrefs ) : $record_set

Fetches a set of one or more records by primary key.

=item visit_select()

  $class_name->visit_select ( $sub_ref, %select_clauses ) : @results
  $class_name->visit_select ( %select_clauses, $sub_ref ) : @results

Calls the provided subroutine on each matching record as it is retrieved. Returns the accumulated results of each subroutine call (in list context).

To Do: This could perform caching of the matched records, but currently does not.

=back

The conversion of select clauses to a SQL statement is performed by the sql_select method:

=over 4

=item sql_select()

  $class_name->sql_select ( %sql_clauses ) : $sql_stmt, @params

Uses the table to call the sql_select method on the current SQLEngine driver. 

=back

=cut

# $records = $record_class->fetch_select( %select_clauses );
sub fetch_select {
  my $self = shift;
  my %clauses = @_;
  
  my @sql = $self->sql_select( %clauses );

  my ($records, $update) = $self->cache_get( \@sql );
  
  if ( ! defined $records ) {
    $records = $self->NEXT('fetch_select', sql => \@sql );
    $update->( $records ) if ( $update and $records );
  }
  
  return $records;
}

sub fetch_one_record {
  local $SIG{__DIE__} = \&Carp::confess;
  (shift)->fetch_select( @_, 'limit' => 1 )->record( 0 )
}

# @results = $self->visit_select( %select_clauses, $sub );
sub visit_select {
  my $self = shift;
  my $sub = ( ref($_[0]) ? shift : pop );
  my %clauses = @_;
  
  my @sql = $self->sql_select( %clauses );
  
  my ($records, $update) = $self->cache_get( \@sql );
  
  if ( $records ) {
    return map &$sub( $_ ), @$records;
  } 
  $self->sqlengine_do('visit_select', @_, $sub )
}

########################################################################

sub sql_select {
  (shift)->get_table->sqlengine_do( 'sql_select', @_ );
}

########################################################################

=head2 Vivifying Records From The Database

These methods are called internally by the various select methods and do not need to be called directly.

=over 4

=item record_from_db_data()

  $class_name->record_from_db_data( $hash_ref )

Calls SUPER method, then cache_records().

=item record_set_from_db_data()

  $class_name->record_set_from_db_data( $hash_array_ref )

Calls SUPER method, then cache_records().

=item cache_records()

  $class_name->cache_records( @records )

Adds records to the cache.

=back

=cut

# $record_class->record_from_db_data( $hash_ref );
sub record_from_db_data {
  my $self = shift;
  my $record = $self->NEXT('record_from_db_data', @_ );
  $self->cache_records( $record );
  $record;
}

# $record_class->record_set_from_db_data( $hash_array_ref );
sub record_set_from_db_data {
  my $self = shift;
  my $recordset = $self->NEXT('record_set_from_db_data', @_ );
  $self->cache_records( @$recordset );
  $recordset;
}

sub cache_records {
  my $self = shift;
  my $id_col = $self->column_primary_name();
  foreach my $record ( @_ ) {
    my $tablename = $self->table->name;
    my $criteria = { $id_col => $record->{ $id_col } };
    my %index = ( where => { $id_col => $record->{ $id_col } }, limit => 1, table => $self->table->name );
    $self->cache_set( \%index, DBIx::SQLEngine::Record::Set->new($record) );
  }
}

########################################################################

########################################################################

=head1 EDITING DATA (SQL DML)

=head2 Insert to Add Records

After constructing a record with one of the new_*() methods, you may save any changes by calling insert_record.

=over 4

=item insert_record

  $record_obj->insert_record() : $flag

Attempt to insert the record into the database. Calls SUPER method, so implemented using MIXIN.

Clears the cache.

=back

=cut

# $record->insert_record()
sub insert_record {
  my $self = shift;
  $self->cache_clear();
  $self->NEXT('insert_record', @_ );
}

########################################################################

=head2 Update to Change Records

After retrieving a record with one of the fetch methods, you may save any changes by calling update_record.

=over 4

=item update_record

  $record_obj->update_record() : $record_count

Attempts to update the record using its primary key as a unique identifier. 
Calls SUPER method, so implemented using MIXIN.

Clears the cache.

=back

=cut

# $record->update_record()
sub update_record {
  my $self = shift;
  $self->cache_clear();
  $self->NEXT('update_record', @_ );
}

########################################################################

=head2 Delete to Remove Records

=over 4

=item delete_record()

  $record_obj->delete_record() : $record_count

Delete this existing record based on its primary key. 
Calls SUPER method, so implemented using MIXIN.

Clears the cache.

=back

=cut

# $record->delete_record()
sub delete_record {
  my $self = shift;
  $self->cache_clear();
  $self->NEXT('delete_record', @_ );
}

########################################################################

########################################################################

=head1 SEE ALSO

For more about the Record classes, see L<DBIx::SQLEngine::Record::Class>.

See L<DBIx::SQLEngine> for the overall interface and developer documentation.

See L<DBIx::SQLEngine::Docs::ReadMe> for general information about
this distribution, including installation and license information.

=cut

########################################################################

1;

__END__

### DBO::Row::CachedRow

### Change History
  # 2000-12-29 Added table_or_die() for better debugging output.
  # 2000-05-24 Adjusted fall-back behavior in fetch_sql.
  # 2000-04-12 Check whether being called on instance or class before blessing.
  # 2000-04-11 Fixed really anoying fetch_id problem. 
  # 2000-04-05 Completed expiration and pruning methods.
  # 2000-04-04 Check for empty-string criteria, ordering in cache_key_for_fetch
  # 2000-03-29 Fixed cache expiration for multi-row fetch.
  # 2000-03-06 Touchups.
  # 2000-01-13 Overhauled. -Simon

########################################################################





########################################################################

# $rows = RowClass->fetch( $criteria, $order )
sub fetch {
  my $self = shift;
  
  return $self->query_cache->cache_get_set(
    $self->cache_key_for_fetch( @_ ),
    \&___cache_fetch, $self, @_
  );
}

# $rows = RowClass->fetch_sql( $sql )
sub fetch_sql {
  my $self = shift;
  
  return $self->query_cache->cache_get_set(
    join('__', @_),
    \&___cache_fetch_sql, $self, @_
  );
}

# $row = RowClass->fetch_id( $id )
sub fetch_id {
  my $self = shift;

  return $self->row_cache->cache_get_set(
    join('__', @_),
    \&___cache_fetch_id, $self, @_
  );
}

########################################################################

sub insert_row {
  my $row = shift;
  
  $row->query_cache->clear_all() if ( $row->query_cache );
  
  my $id_col = $row->table_or_die()->id_column();
  my $row_cache = $row->row_cache;
  if ( $id_col and $row_cache ) {
    $row_cache->replace( $row->{$id_col}, $row );
  }
  
  return $row->NEXT('insert_row', @_);
}

sub update_row {
  my $row = shift;
  $row->query_cache->clear_all() if ( $row->query_cache );
  return $row->NEXT('update_row', @_);
}

sub delete_row {
  my $row = shift;
  
  my $id_col = $row->table_or_die()->id_column();
  my $row_cache = $row->row_cache;
  if ( $id_col and $row_cache ) {
    $row_cache->clear( $row->{$id_col} );
  }
  
  $row->query_cache->clear_all() if ( $row->query_cache );
  return $row->NEXT('delete_row, @_);
}

1;
