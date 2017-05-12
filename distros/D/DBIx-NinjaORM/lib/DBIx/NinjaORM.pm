package DBIx::NinjaORM;

use 5.010;

use warnings;
use strict;

use Carp;
use Class::Load qw();
use DBIx::NinjaORM::StaticClassInfo;
use DBIx::NinjaORM::Utils qw( dumper );
use Data::Validate::Type;
use Digest::SHA1 qw();
use Log::Any qw( $log );
use MIME::Base64 qw();
use Storable;
use Try::Tiny;


=head1 NAME

DBIx::NinjaORM - Flexible Perl ORM for easy transitions from inline SQL to objects.


=head1 VERSION

Version 3.1.0

=cut

our $VERSION = '3.1.0';


=head1 DESCRIPTION

L<DBIx::NinjaORM> was designed with a few goals in mind:

=over 4

=item *

Expand objects with data joined from other tables, to do less queries and
prevent lazy-loading of ancillary information.

=item *

Have a short learning curve.

=item *

Provide advanced caching features and manage cache expiration upon database changes.

=item *

Allow a progressive introduction of a separate Model layer in a legacy codebase.

=back


=head1 SYNOPSIS

=head2 Simple example

Let's take the example of a C<My::Model::Book> class that represents a book. You
would start C<My::Model::Book> with the following code:

	package My::Model::Book;

	use strict;
	use warnings;

	use base 'DBIx::NinjaORM';

	use DBI;


	sub static_class_info
	{
		my ( $class ) = @_;

		# Retrieve defaults from DBIx::Ninja->static_class_info().
		my $info = $class->SUPER::static_class_info();

		$info->set(
			{
				# Set mandatory defaults.
				table_name       => 'books',
				primary_key_name => 'book_id',
				default_dbh      => DBI->connect(
					"dbi:mysql:[database_name]:localhost:3306",
					"[user]",
					"[password]",
				),

				# Add optional information.
				# Allow filtering SELECTs on books.name.
				filtering_fields => [ 'name' ],
			}
		);

		return $info;
	}

	1;

Inheriting with C<use base 'DBIx::NinjaORM'> and creating
C<sub static_class_info> (with a default database handle and a table name)
are the only two requirements to have a working model.


=head2 A more complex model

If you have more than one Model class to create, for example C<My::Model::Book>
and C<My::Model::Library>, you probably want to create a single class
C<My::Model> to hold the defaults and then inherits from that main class.

	package My::Model;

	use strict;
	use warnings;

	use base 'DBIx::NinjaORM';

	use DBI;
	use Cache::Memcached::Fast;


	sub static_class_info
	{
		my ( $class ) = @_;

		# Retrieve defaults from DBIx::Ninja->static_class_info().
		my $info = $class->SUPER::static_class_info();

		# Set defaults common to all your objects.
		$info->set(
			{
				default_dbh => DBI->connect(
					"dbi:mysql:[database_name]:localhost:3306",
					"[user]",
					"[password]",
				),
				memcache    => Cache::Memcached::Fast->new(
					{
						servers =>
						[
							'localhost:11211',
						],
					}
				),
			}
		);

		return $info;
	}

	1;

The various classes will then inherit from C<My::Model>, and the inherited
defaults will make C<static_class_info()> shorter in the other classes:

	package My::Model::Book;

	use strict;
	use warnings;

	# Inherit from your base model class, not from DBIx::NinjaORM.
	use base 'My::Model';

	sub static_class_info
	{
		my ( $class ) = @_;

		# Retrieve defaults from My::Model.
		my $info = $class->SUPER::static_class_info();

		$info->set(
			{
				# Set mandatory defaults for this class.
				table_name       => 'books',
				primary_key_name => 'book_id',

				# Add optional information.
				# Allow filtering SELECTs on books.name.
				filtering_fields => [ 'name' ],
			}
		);

		return $info;
	}

	1;

=cut

# This hash indicates what argument names are valid in retrieve_list() calls,
# and for each argument it specifies whether it should be included (1) or
# ignored (0) when building the list cache keys that associate the arguments
# passed to the result IDs.
our $RETRIEVE_LIST_VALID_ARGUMENTS =
{
	allow_all        => 1,
	dbh              => 0,
	limit            => 1,
	lock             => 0,
	order_by         => 1,
	pagination       => 1,
	query_extensions => 1,
	show_queries     => 0,
	skip_cache       => 0,
	exclude_fields   => 0,
	select_fields    => 0,
};


=head1 SUPPORTED DATABASES

This distribution currently supports:

=over 4

=item * SQLite

=item * MySQL

=item * PostgreSQL

=back

Please contact me if you need support for another database type, I'm always
glad to add extensions if you can help me with testing.


=head1 SUBCLASSABLE METHODS

L<DBIx::NinjaORM> is designed with inheritance in mind, and you can subclass
most of its public methods to extend or alter its behavior.

This group of method covers the most commonly subclassed methods, with examples
and use cases.


=head2 clone()

Clone the current object and return the clone.

	my $cloned_book = $book->clone();

=cut

sub clone
{
	my ( $self ) = @_;

	return Storable::dclone( $self );
}


=head2 commit()

Convenience function to insert or update the object.

If the object has a primary key set, C<update()> is called, otherwise
C<insert()> is called. If there's an error, the method with croak with
relevant error information.

	$book->commit();

Arguments: (none).

=cut

sub commit
{
	my ( $self ) = @_;
	my $data = Storable::dclone( $self );

	if ( defined( $self->id() ) )
	{
		# If id() is defined, we have a value for the primary key name
		# and we need to delete it from the data to update.
		my $primary_key_name = $self->get_info('primary_key_name');
		delete( $data->{ $primary_key_name } );

		return $self->update( $data );
	}
	else
	{
		return $self->insert( $data );
	}
}


=head2 get()

Get the value corresponding to an object's field.

	my $book_name = $book->get('name');

This method will croak if you attempt to retrieve a private field. It also
detects if the object was retrieved from the database, in which case it
has an exhaustive list of the fields that actually exist in the database and
it will croak if you attempt to retrieve a field that doesn't exist in the
database.

=cut

sub get
{
	my ( $self, $field_name ) = @_;

	croak "The name of the field to retrieve must be defined"
		if !defined( $field_name ) || ( $field_name eq '' );

	# Create your own accessor for private properties.
	croak 'Cannot retrieve the value of a private object property, create an accessor on the class if you need this value'
		if substr( $field_name, 0, 1 ) eq '_';

	# If the object was not populated by retrieve_list(), we know that the keys
	# on the object correspond to all the columns in the database and we can then
	# actively show errors in the log if the caller is requesting a field for
	# which the key doesn't exist.
	my $populated_by_retrieve_list = $self->{'_populated_by_retrieve_list'} // 0;
	croak "The property '$field_name' does not exist on the object"
		if $populated_by_retrieve_list && !exists( $self->{ $field_name } );

	return $self->{ $field_name };
}


=head2 get_current_time()

Return the current time, to use in SQL statements.

	my $current_time = $class->get_current_time( $field_name );

By default, DBIx::NinjaORM assumes that time is stored as unixtime (integer) in the database. If you are using a different field type for C<created> and C<modified>, you can subclass this method to return the current time in a different format.

Arguments:

=over 4

=item * $field_name

The name of the field that will be populated with the return value.

=back

Notes:

=over 4

=item *

The return value of this method will be inserted directly into the database, so
you can use C<NOW()> for example, and if you are inserting strings those should
be quoted in the subclassed method.

=back

=cut

sub get_current_time
{
	my ( $self, $field_name ) = @_;

	return time();
}


=head2 insert()

Insert a row corresponding to the data passed as first parameter, and fill the
object accordingly upon success.

	my $book = My::Model::Book->new();
	$book->insert(
		{
			name => 'Learning Perl',
		}
	);

If you don't need the object afterwards, you can simply do:

	My::Model::Book->insert(
		{
			name => 'Learning Perl',
		}
	);

This method supports the following optional arguments:

=over 4

=item * overwrite_created

A UNIX timestamp to be used instead of the current time for the value of
'created'.

=item * generated_primary_key_value

A primary key value, in case the underlying table doesn't have an
autoincremented primary key.

=item * dbh

A different database handle than the default one specified in
C<static_class_info()>, but it has to be writable.

=item * ignore

INSERT IGNORE instead of plain INSERT.

=back

	$book->insert(
		\%data,
		overwrite_created           => $unixtime,
		generated_primary_key_value => $value,
		dbh                         => $dbh,
		ignore                      => $boolean,
	);

=cut

sub insert ## no critic (Subroutines::RequireArgUnpacking)
{
	croak 'The first argument passed must be a hashref'
		if !Data::Validate::Type::is_hashref( $_[1] );

	my ( $self, $data, %args ) = @_;

	# Allows calling Module->insert() if we don't need the object afterwards.
	# In this case, we turn $self from a class into an object.
	$self = $self->new()
		if !ref( $self );

	# Allow using a different database handle.
	my $dbh = $self->assert_dbh( $args{'dbh'} );

	# Clean input.
	my $clean_data = $self->validate_data( $data, %args );
	return 0
		if !defined( $clean_data );

	# Retrieve the metadata for that table.
	my $class = ref( $self );
	my $table_name = $self->get_info('table_name');
	croak "The table name for class '$class' is not defined"
		if !defined( $table_name );

	my $primary_key_name = $self->get_info('primary_key_name');
	croak "Missing primary key name for class '$class', cannot force primary key value"
		if !defined( $primary_key_name ) && defined( $args{'generated_primary_key_value'} );

	# Set defaults.
	if ( $self->get_info('has_created_field') )
	{
		$clean_data->{'created'} = defined( $args{'overwrite_created'} ) && $args{'overwrite_created'} ne ''
			? $args{'overwrite_created'}
			: $self->get_current_time();
	}
	$clean_data->{'modified'} = $self->get_current_time()
		if $self->get_info('has_modified_field');
	$clean_data->{ $primary_key_name } = $args{'generated_primary_key_value'}
		if defined( $args{'generated_primary_key_value'} );

	# Prepare the query elements.
	my $ignore = defined( $args{'ignore'} ) && $args{'ignore'} ? 1 : 0;
	my @sql_fields = ();
	my @sql_values = ();
	my @placeholder_values = ();
	foreach my $key ( keys %$clean_data )
	{
		push( @sql_fields, $key );

		# 'created' and 'modified' support SQL keywords, so we don't use
		# placeholders.
		if ( $key =~ /^(?:created|modified)$/x )
		{
			push( @sql_values, $clean_data->{ $key } );
		}
		else
		{
			# All the other data need to be inserted using placeholders, for
			# security purposes.
			push( @sql_values, '?' );
			push( @placeholder_values, $clean_data->{ $key } );
		}
	}

	my $query = sprintf(
		q|
			INSERT %s INTO %s( %s )
			VALUES ( %s )
		|,
		$ignore ? 'IGNORE' : '',
		$dbh->quote_identifier( $table_name ),
		join( ', ', @sql_fields ),
		join( ', ', @sql_values ),
	);

	# Insert.
	try
	{
		local $dbh->{'RaiseError'} = 1;
		$dbh->do(
			$query,
			{},
			@placeholder_values,
		);
	}
	catch
	{
		$log->fatalf(
			"Could not insert row: %s\nQuery: %s\nValues: %s",
			$_,
			$query,
			\@placeholder_values,
		);
		croak "Insert failed: $_";
	};

	if ( defined( $primary_key_name ) )
	{
		$clean_data->{ $primary_key_name } = defined( $args{'generated_primary_key_value'} )
			? $args{'generated_primary_key_value'}
			: $dbh->last_insert_id( undef, undef, $table_name, $primary_key_name );
	}

	# Check that the object was correctly inserted.
	croak "Could not insert into table '$table_name': " . dumper( $data )
		if defined( $primary_key_name ) && !defined( $clean_data->{ $primary_key_name } );

	# Make sure that the object reflects the changes in the database.
	$self->set(
		$clean_data,
		force => 1,
	);

	return;
}


=head2 new()

C<new()> has two possible uses:

=over 4

=item * Creating a new empty object

	my $object = My::Model::Book->new();

=item * Retrieving a single object from the database.

	# Retrieve by ID.
	my $object = My::Model::Book->new( { id => 3 } )
		// die 'Book #3 does not exist';

	# Retrieve by unique field.
	my $object = My::Model::Book->new( { isbn => '9781449303587' } )
		// die 'Book with ISBN 9781449303587 does not exist';

=back

When retrieving a single object from the database, the first argument should be
a hashref containing the following information to select a single row:

=over 4

=item * id

The ID for the primary key on the underlying table. C<id> is an alias for the
primary key field name.

	my $object = My::Model::Book->new( { id => 3 } )
		// die 'Book #3 does not exist';

=item * A unique field

Allows passing a unique field and its value, in order to load the
corresponding object from the database.

	my $object = My::Model::Book->new( { isbn => '9781449303587' } )
		// die 'Book with ISBN 9781449303587 does not exist';

Note that unique fields need to be defined in C<static_class_info()>, in the
C<unique_fields> key.

=back

This method also supports the following optional arguments, passed in a hash
after the filtering criteria above-mentioned:

=over 4

=item * skip_cache (default: 0)

By default, if cache is enabled with C<object_cache_time()> in
C<static_class_info()>, then C<new> attempts to load the object from the cache
first. Setting C<skip_cache> to 1 forces the ORM to load the values from the
database.

	my $object = My::Model::Book->new(
		{ isbn => '9781449303587' },
		skip_cache => 1,
	) // die 'Book with ISBN 9781449303587 does not exist';

=item * lock (default: 0)

By default, the underlying row is not locked when retrieving an object via
C<new()>. Setting C<lock> to 1 forces the ORM to bypass the cache if any, and
to lock the rows in the database as it retrieves them.

	my $object = My::Model::Book->new(
		{ isbn => '9781449303587' },
		lock => 1,
	) // die 'Book with ISBN 9781449303587 does not exist';

=back

=cut

sub new
{
	my ( $class, $filters, %args ) = @_;

	# If filters exist, they need to be a hashref.
	croak 'The first argument must be a hashref containing filtering criteria'
		if defined( $filters ) && !Data::Validate::Type::is_hashref( $filters );

	# Check if we have a unique identifier passed.
	# Note: passing an ID is a subcase of passing field defined as unique, but
	# unique_fields() doesn't include the primary key name.
	my $unique_field;
	foreach my $field ( 'id', @{ $class->get_info('unique_fields') // [] } )
	{
		next
			if ! exists( $filters->{ $field } );

		# If the field exists in the list of filters, it needs to be
		# defined. Being undefined probably indicates a problem in the calling code.
		croak "Called new() with '$field' declared but not defined"
			if ! defined( $filters->{ $field } );

		# Detect if we're passing two unique fields to retrieve the object. This is
		# obviously bad.
		croak "Called new() with the unique argument '$field', but already found another unique argument '$unique_field'"
			if defined( $unique_field );

		$unique_field = $field;
	}

	# Retrieve the object.
	my $self;
	if ( defined( $unique_field ) )
	{
		my $objects = $class->retrieve_list(
			{
				$unique_field => $filters->{ $unique_field },
			},
			skip_cache    => $args{'skip_cache'},
			lock          => $args{'lock'} ? 1 : 0,
		);

		my $objects_count = scalar( @$objects );
		if ( $objects_count == 0 )
		{
			# No row found.
			$self = undef;
		}
		elsif ( $objects_count == 1 )
		{
			$self = $objects->[0];
		}
		else
		{
			croak "Called new() with a set of non-unique arguments that returned $objects_count objects: " . dumper( \%args );
		}
	}
	else
	{
		$self = bless( {}, $class );
	}

	return $self;
}


=head2 remove()

Delete in the database the row corresponding to the current object.

	$book->remove();

This method accepts the following arguments:

=over 4

=item * dbh

A different database handle from the default specified in C<static_class_info()>.
This is particularly useful if you have separate reader/writer databases.

=back

=cut

sub remove
{
	my ( $self, %args ) = @_;

	# Retrieve the metadata for that table.
	my $class = ref( $self );
	my $table_name = $self->get_info('table_name');
	croak "The table name for class '$class' is not defined"
		if ! defined( $table_name );

	my $primary_key_name = $self->get_info('primary_key_name');
	croak "Missing primary key name for class '$class', cannot delete safely"
		if !defined( $primary_key_name );

	croak "The object of class '$class' does not have a primary key value, cannot delete"
		if ! defined( $self->id() );

	# Allow using a different DB handle.
	my $dbh = $self->assert_dbh( $args{'dbh'} );

	# Prepare the query.
	my $query = sprintf(
		q|
			DELETE
			FROM %s
			WHERE %s = ?
		|,
		$dbh->quote_identifier( $table_name ),
		$dbh->quote_identifier( $primary_key_name ),
	);
	my @query_values = ( $self->id() );

	# Delete the row.
	try
	{
		local $dbh->{'RaiseError'} = 1;
		$dbh->do(
			$query,
			{},
			@query_values,
		);
	}
	catch
	{
		$log->fatalf(
			"Could not delete row: %s\nQuery: %s\nValues: %s",
			$_,
			$query,
			\@query_values,
		);
		croak "Remove failed: $_";
	};

	return;
}


=head2 retrieve_list_nocache()

Dispatch of retrieve_list() when objects should not be retrieved from the cache.

See C<retrieve_list()> for the parameters this method accepts.

=cut

sub retrieve_list_nocache ## no critic (Subroutines::ProhibitExcessComplexity)
{
	my ( $class, $filters, %args ) = @_;

	# Handle a different database handle, if requested.
	my $dbh = $class->assert_dbh( $args{'dbh'} );

	# TODO: If we're asked to lock the rows, we check that we're in a transaction.

	# Check if we were passed arguments we don't know how to handle. This will
	# help the calling code to detect typos or deprecated arguments.
	foreach my $arg ( keys %args )
	{
		next if defined( $RETRIEVE_LIST_VALID_ARGUMENTS->{ $arg } );

		croak(
			"The argument '$arg' passed to DBIx::NinjaORM->retrieve_list() via " .
			"${class}->retrieve_list() is not handled by the superclass. " .
			"It could mean that you have a typo in the name or that the argument has " .
			"been deprecated."
		);
	}

	# Check the parameters and prepare the corresponding where clauses.
	my $where_clauses = $args{'query_extensions'}->{'where_clauses'} || [];
	my $where_values = $args{'query_extensions'}->{'where_values'} || [];
	my $filtering_field_keys_passed = 0;
	my $filtering_criteria = $class->parse_filtering_criteria(
		$filters
	);
	if ( defined( $filtering_criteria ) )
	{
		push( @$where_clauses, @{ $filtering_criteria->[0] || [] } );
		push( @$where_values, @{ $filtering_criteria->[1] || [] } );
		$filtering_field_keys_passed = $filtering_criteria->[2];
	}

	# Make sure there's at least one argument, unless allow_all=1 or there is
	# custom where clauses.
	croak 'At least one argument must be passed'
		if !$args{'allow_all'} && !$filtering_field_keys_passed && scalar( @$where_clauses ) == 0;

	# Prepare the ORDER BY.
	my $table_name = $class->get_info('table_name');
	my $order_by = defined( $args{'order_by'} ) && ( $args{'order_by'} ne '' )
		? "ORDER BY $args{'order_by'}"
		: $class->get_info('has_created_field')
			? "ORDER BY " . $dbh->quote_identifier( $table_name ) . ".created ASC"
			: "ORDER BY " . $dbh->quote_identifier( $table_name ) . '.' . $class->get_info('primary_key_name');

	# Prepare quoted identifiers.
	my $primary_key_name = $class->get_info('primary_key_name');
	my $quoted_primary_key_name = $dbh->quote_identifier( $primary_key_name );
	my $quoted_table_name = $dbh->quote_identifier( $table_name );

	# Prepare the SQL request elements.
	my $where = scalar( @$where_clauses ) != 0
		? 'WHERE ( ' . join( ' ) AND ( ', @$where_clauses ) . ' )'
		: '';
	my $joins = $args{'query_extensions'}->{'joins'} || '';
	my $limit = defined( $args{'limit'} ) && ( $args{'limit'} =~ m/^\d+$/ )
		? 'LIMIT ' . $args{'limit'}
		: '';

	# Prepare the list of fields to retrieve.
	my $fields;
	if ( defined( $args{'exclude_fields'} ) || defined( $args{'select_fields'} ) )
	{
		my $table_schema = $class->get_table_schema();
		croak "Failed to retrieve schema for table '$table_name'"
			if !defined( $table_schema );
		my $column_names = $table_schema->get_column_names();
		croak "Failed to retrieve column names for table '$table_name'"
			if !defined( $column_names );

		my @filtered_fields = ();
		if ( defined( $args{'exclude_fields'} ) && !defined( $args{'select_fields'} ) )
		{
			my %excluded_fields = map { $_ => 1 } @{ $args{'exclude_fields'} };
			foreach my $field ( @$column_names )
			{
				$excluded_fields{ $field }
					? delete( $excluded_fields{ $field } )
					: push( @filtered_fields, $field );
			}
			croak "The following excluded fields are not valid: " . join( ', ', keys %excluded_fields )
				if scalar( keys %excluded_fields ) != 0;
		}
		elsif ( !defined( $args{'exclude_fields'} ) && defined( $args{'select_fields'} ) )
		{
			my %selected_fields = map { $_ => 1 } @{ $args{'select_fields'} };
			croak 'The primary key must be in the list of selected fields'
				if defined( $primary_key_name ) && !$selected_fields{ $primary_key_name };

			foreach my $field ( @$column_names )
			{
				next if !$selected_fields{ $field };
				push( @filtered_fields, $field );
				delete( $selected_fields{ $field } );
			}

			croak "The following restricted fields are not valid: " . join( ', ', keys %selected_fields )
				if scalar( keys %selected_fields ) != 0;
		}
		else
		{
			croak "The 'exclude_fields' and 'select_fields' options are not compatible, use one or the other";
		}

		croak "No fields left after filtering out the excluded/restricted fields"
			if scalar( @filtered_fields ) == 0;

		$fields = join(
			', ',
			map { "$quoted_table_name.$_" } @filtered_fields
		);
	}
	else
	{
		$fields = $quoted_table_name . '.*';
	}

	$fields .= ', ' . $args{'query_extensions'}->{'joined_fields'}
		if defined( $args{'query_extensions'}->{'joined_fields'} );

	# We need to make an exception for lock=1 when using SQLite, since
	# SQLite doesn't support FOR UPDATE.
	# Per http://sqlite.org/cvstrac/wiki?p=UnsupportedSql, the entire
	# database is locked when updating any bit of it, so we can simply
	# ignore the locking request here.
	my $lock = '';
	if ( $args{'lock'} )
	{
		my $database_type = $dbh->{'Driver'}->{'Name'} || '';
		if ( $database_type eq 'SQLite' )
		{
			$log->info(
				'SQLite does not support locking since only one process at a time is ',
				'allowed to update a given SQLite database, so lock=1 is ignored.',
			);
		}
		else
		{
			$lock = 'FOR UPDATE';
		}
	}

	# Check if we need to paginate.
	my $pagination_info = {};
	if ( defined( $args{'pagination'} ) )
	{
		# Allow for pagination => 1 as a shortcut to get all the defaults.
		$args{'pagination'} = {}
			if !Data::Validate::Type::is_hashref( $args{'pagination'} ) && ( $args{'pagination'} eq '1' );

		# Set defaults.
		$pagination_info->{'per_page'} = ( $args{'pagination'}->{'per_page'} || '' ) =~ m/^\d+$/
			? $args{'pagination'}->{'per_page'}
			: 20;

		# Count the total number of results.
		my $count_data = $dbh->selectrow_arrayref(
			sprintf(
				q|
					SELECT COUNT(*)
					FROM %s
					%s
					%s
				|,
				$quoted_table_name,
				$joins,
				$where,
			),
			{},
			map { @$_ } @$where_values,
		);
		$pagination_info->{'total_count'} = defined( $count_data ) && scalar( @$count_data ) != 0
			? $count_data->[0]
			: undef;

		# Calculate what the max page can be.
		$pagination_info->{'page_max'} = int( ( $pagination_info->{'total_count'} - 1 ) / $pagination_info->{'per_page'} ) + 1;

		# Determine what the current page is.
		$pagination_info->{'page'} = ( ( $args{'pagination'}->{'page'} || '' ) =~ m/^\d+$/ ) && ( $args{'pagination'}->{'page'} > 0 )
			? $pagination_info->{'page_max'} < $args{'pagination'}->{'page'}
				? $pagination_info->{'page_max'}
				: $args{'pagination'}->{'page'}
			: 1;

		# Set LIMIT and OFFSET.
		$limit = "LIMIT $pagination_info->{'per_page'} "
			. 'OFFSET ' . ( ( $pagination_info->{'page'} - 1 ) * $pagination_info->{'per_page'} );
	}

	# If we need to lock the rows and there's joins, let's do this in two steps:
	# 1) Lock the rows without join.
	# 2) Using the IDs found, do another select to retrieve the data with the joins.
	if ( ( $lock ne '' ) && ( $joins ne '' ) )
	{
		my $query = sprintf(
			q|
				SELECT %s
				FROM %s
				%s
				ORDER BY %s ASC
				%s
				%s
			|,
			$quoted_primary_key_name,
			$quoted_table_name,
			$where,
			$quoted_primary_key_name,
			$limit,
			$lock,
		);

		my @query_values = map { @$_ } @$where_values;
		$log->debugf(
			"Performing pre-locking query:\n%s\nValues:\n%s",
			$query,
			\@query_values,
		) if $args{'show_queries'};

		my $locked_ids;
		try
		{
			local $dbh->{'RaiseError'} = 1;
			$locked_ids = $dbh->selectall_arrayref(
				$query,
				{
					Columns => [ 1 ],
				},
				@query_values
			);
		}
		catch
		{
			$log->fatalf(
				"Could not select rows in pre-locking query: %s\nQuery: %s\nValues:\n%s",
				$_,
				$query,
				\@query_values,
			);
			croak "Failed select: $_";
		};

		if ( !defined( $locked_ids ) || ( scalar( @$locked_ids ) == 0 ) )
		{
			return [];
		}

		$where = sprintf(
			'WHERE %s.%s IN ( %s )',
			$quoted_table_name,
			$quoted_primary_key_name,
			join( ', ', ( ('?') x scalar( @$locked_ids ) ) ),
		);
		$where_values = [ [ map { $_->[0] } @$locked_ids ] ];
		$lock = '';
	}

	# Prepare the query elements.
	my $query = sprintf(
		q|
			SELECT %s
			FROM %s
			%s %s %s %s %s
		|,
		$fields,
		$quoted_table_name,
		$joins,
		$where,
		$order_by,
		$limit,
		$lock,
	);
	my @query_values = map { @$_ } @$where_values;
	$log->debugf(
		"Performing query:\n%s\nValues:\n%s",
		$query,
		\@query_values,
	) if $args{'show_queries'};

	# Retrieve the objects.
	my $sth;
	try
	{
		local $dbh->{'RaiseError'} = 1;
		$sth = $dbh->prepare( $query );
		$sth->execute( @query_values );
	}
	catch
	{
		$log->fatalf(
			"Could not select rows: %s\nQuery: %s\nValues: %s",
			$_,
			$query,
			\@query_values,
		);
		croak "Failed select: $_";
	};

	my $object_list = [];
	while ( my $ref = $sth->fetchrow_hashref() )
	{
		my $object = Storable::dclone( $ref );
		bless( $object, $class );

		$object->reorganize_non_native_fields();

		# Add a flag to distinguish objects that were populated via
		# retrieve_list_nocache(), as those objects are known for sure to contain
		# all the keys for columns that exist in the database. We also won't have to
		# worry about missing defaults, like insert() would have to.
		$object->{'_populated_by_retrieve_list'} = 1;

		# Add cache debugging information.
		$object->{'_debug'}->{'list_cache_used'} = 0;
		$object->{'_debug'}->{'object_cache_used'} = 0;

		# Store if we've excluded any fields, as it will impact caching in
		# retrieve_list().
		$object->{'_excluded_fields'} = $args{'exclude_fields'}
			if defined( $args{'exclude_fields'} );

		# Store if we've restricted to any fields, as it will impact caching in
		# retrieve_list().
		$object->{'_selected_fields'} = $args{'select_fields'}
			if defined( $args{'select_fields'} );

		push( @$object_list, $object );
	}

	if ( wantarray && defined( $args{'pagination'} ) )
	{
		return ( $object_list, $pagination_info );
	}
	else
	{
		return $object_list;
	}
}


=head2 set()

Set fields and values on an object.

	$book->set(
		{
			name => 'Learning Perl',
			isbn => '9781449303587',
		},
	);

This method supports the following arguments:

=over 4

=item * force

Set the properties on the object without going through C<validate_data()>.

	$book->set(
		{
			name => 'Learning Perl',
			isbn => '9781449303587',
		},
		force => 1,
	);

=back

=cut

sub set ## no critic (NamingConventions::ProhibitAmbiguousNames, Subroutines::RequireArgUnpacking)
{
	croak 'The first argument passed must be a hashref'
		if !Data::Validate::Type::is_hashref( $_[1] );

	my ( $self, $data, %args ) = @_;

	# Validate the data first, unless force=1.
	$data = $self->validate_data( $data )
		if !$args{'force'};

	# Update the object.
	foreach ( keys %$data )
	{
		$self->{ $_ } = $data->{ $_ };
	}

	return;
}


=head2 static_class_info()

This methods sets defaults as well as general information for a specific class.

It allows for example indicating what table the objects will be related to, or
what database handle to use. See L<DBIx::NinjaORM::StaticClassInfo> for the
full list of options that can be set or overridden.

Here's what a typical subclassed C<static_class_info()> would look like:

	sub static_class_info
	{
		my ( $class ) = @_;

		# Retrieve defaults coming from higher in the inheritance chain, up
		# to DBIx::NinjaORM->static_class_info().
		my $info = $class->SUPER::static_class_info();

		# Set or override information.
		$info->set(
			{
				table_name       => 'books',
				primary_key_name => 'book_id',
				default_dbh      => DBI->connect(
					"dbi:mysql:[database_name]:localhost:3306",
					"[user]",
					"[password]",
				),
			}
		);

		# Return the updated information hashref.
		return $info;
	}

=cut

sub static_class_info
{
	return DBIx::NinjaORM::StaticClassInfo->new();
}


=head2 update()

Update the row in the database corresponding to the current object, using the
primary key and its value on the object.

	$book->update(
		{
			name => 'Learning Perl',
		}
	);

This method supports the following optional arguments:

=over 4

=item * skip_modified_update (default 0)

Do not update the 'modified' field. This is useful if you're using 'modified' to
record when was the last time a human changed the row, but you want to exclude
automated changes.

=item * dbh

A different database handle than the default one specified in
C<static_class_info()>, but it has to be writable.

=item * restrictions

The update statement is limited using the primary key. This parameter however
allows adding extra restrictions on the update. Additional clauses passed here
are joined with AND.

	$book->update(
		{
			author_id => 1234,
		},
		restrictions =>
		{
			where_clauses => [ 'status != ?' ],
			where_values  => [ 'protected' ],
		},
	);

=item * set

\%data contains the data to update the row with "SET field = value". It is
however sometimes necessary to use more complex SETs, such as
"SET field = field + value", which is what this parameter allows.

Important: you will need to subclass C<update()> in your model classes and
update manually the values upon success (or reload the object), as
L<DBIx::NinjaORM> cannot determine the end result of those complex sets on the
database side.

	$book->update(
		{
			name => 'Learning Perl',
		},
		set =>
		{
			placeholders => [ 'edits = edits + ?' ],
			values       => [ 1 ],
		}
	);

=back

=cut

sub update ## no critic (Subroutines::RequireArgUnpacking)
{
	croak 'The first argument passed must be a hashref'
		if !Data::Validate::Type::is_hashref( $_[1] );

	my ( $self, $data, %args ) = @_;

	# Allow using a different DB handle.
	my $dbh = $self->assert_dbh( $args{'dbh'} );

	# Clean input
	my $clean_data = $self->validate_data( $data, %args );
	return 0
		if !defined( $clean_data );

	# Set defaults
	$clean_data->{'modified'} = $self->get_current_time()
		if !$args{'skip_modified_update'} && $self->get_info('has_modified_field');

	# If there's nothing to update, bail out.
	if ( scalar( keys %$clean_data ) == 0 )
	{
		$log->debug( 'No data left to update after validation, skipping SQL update' )
			if $self->is_verbose();
		return;
	}

	# Retrieve the meta-data for that table.
	my $class = ref( $self );

	my $table_name = $self->get_info('table_name');
	croak "The table name for class '$class' is not defined"
		if ! defined( $table_name );

	my $primary_key_name = $self->get_info('primary_key_name');
	croak "Missing primary key name for class '$class', cannot force primary key value"
		if !defined( $primary_key_name ) && defined( $args{'generated_primary_key_value'} );

	croak "The object of class '$class' does not have a primary key value, cannot update"
		if ! defined( $self->id() );

	# Prepare the SQL request elements.
	my $where_clauses = $args{'restrictions'}->{'where_clauses'} || [];
	my $where_values = $args{'restrictions'}->{'where_values'} || [];
	push( @$where_clauses, $primary_key_name . ' = ?' );
	push( @$where_values, [ $self->id() ] );

	# Prepare the values to set.
	my @set_placeholders = ();
	my @set_values = ();
	foreach my $key ( keys %$clean_data )
	{
		if ( $key eq 'modified' )
		{
			# 'created' supports SQL keywords and is quoted by get_current_time() if
			# needed, so we don't use placeholders.
			push( @set_placeholders, $dbh->quote_identifier( $key ) . ' = ' . $clean_data->{ $key } );
		}
		else
		{
			# All the other data need to be inserted using placeholders, for
			# security purposes.
			push( @set_placeholders, $dbh->quote_identifier( $key ) . ' = ?' );
			push( @set_values, $clean_data->{ $key } );
		}
	}
	if ( defined( $args{'set'} ) )
	{
		push( @set_placeholders, @{ $args{'set'}->{'placeholders'} // [] } );
		push( @set_values, @{ $args{'set'}->{'values'} // [] } );
	}

	# Prepare the query elements.
	my $query = sprintf(
		qq|
			UPDATE %s
			SET %s
			WHERE %s
		|,
		$dbh->quote_identifier( $table_name ),
		join( ', ', @set_placeholders ),
		'( ' . join( ' ) AND ( ', @$where_clauses ) . ' )',
	);
	my @query_values =
	(
		@set_values,
		map { @$_ } @$where_values,
	);

	# Update the row.
	my $rows_updated_count;
	try
	{
		local $dbh->{'RaiseError'} = 1;
		my $sth = $dbh->prepare( $query );
		$sth->execute( @query_values );

		$rows_updated_count = $sth->rows();
	}
	catch
	{
		$log->fatalf(
			"Could not update rows: %s\nQuery: %s\nValues: %s",
			$_,
			$query,
			\@query_values,
		);

		croak "Update failed: $_";
	};

	# Also, if rows() returns -1, it's an error.
	croak 'Could not execute update: ' . $dbh->errstr()
		if $rows_updated_count < 0;

	my $object_cache_time = $self->get_info('object_cache_time');
	# This needs to be before the set() below, so we invalidate the cache based on the
	# old object. We don't need to do it twice, because you can't change primary IDs, and
	# you can't change unique fields to ones that are taken, and that's all that we set
	# the object cache keys for.
	if ( defined( $object_cache_time ) )
	{
		$log->debugf(
			"An update on '%s' is forcing to clear the cache for '%s=%s'",
			$table_name,
			$primary_key_name,
			$self->id(),
		) if $self->is_verbose();

		$self->invalidate_cached_object();
	}

	# Make sure that the object reflects $clean_data.
	$self->set(
		$clean_data,
		force => 1,
	);

	return $rows_updated_count;
}


=head2 validate_data()

Validate the hashref of data passed as first argument. This is used both by
C<insert()> and C<update> to check the data before performing databse
operations.

	my $validated_data = $object->validate_data(
		\%data,
	);

If there is invalid data, the method will croak with a detail of the error.

=cut

sub validate_data
{
	my ( $self, $original_data ) = @_;

	my $data = Storable::dclone( $original_data );

	# Protect read-only fields.
	foreach my $field ( @{ $self->get_info('readonly_fields') // [] } )
	{
		next if ! exists( $data->{ $field } );

		croak "The field '$field' is read-only and cannot be set via the model";
	}

	# Don't allow setting timestamps.
	foreach my $field ( qw( created modified ) )
	{
		next if ! exists( $data->{ $field } );

		$log->warnf(
			"The field '%s' cannot be set and will be ignored",
			$field,
		);
		delete( $data->{ $field } );
	}

	# Allow inserting the primary key, but not updating it.
	my $primary_key_name = $self->get_info('primary_key_name');
	if ( defined( $primary_key_name ) && defined( $self->{ $primary_key_name } ) && exists( $data->{ $primary_key_name } ) )
	{
		croak "'$primary_key_name' with a value of '" . ( $data->{ $primary_key_name } || 'undef' ) . "' ",
			"was passed to set(), but primary keys cannot be set manually";
	}

	# Fields starting with an underscore are hidden data that shouldn't be
	# modified via a public interface.
	foreach my $field ( keys %$data )
	{
		delete( $data->{ $field } )
			if substr( $field, 0, 1 ) eq '_';
	}

	return $data;
}


=head1 UTILITY METHODS


=head2 dump()

Return a string representation of the current object.

	my $string = $book->dump();

=cut

sub dump ## no critic (Subroutines::ProhibitBuiltinHomonyms)
{
	my ( $self ) = @_;

	return dumper( $self );
}


=head2 flatten_object()

Return a hash with the requested key/value pairs based on the list of fields
provided.

Note that non-native fields (starting with an underscore) are not allowed. It
also protects sensitive fields.

#TODO: allow defining sensitive fields.

	my $book_data = $book->flatten_object(
		[ 'name', 'isbn' ]
	);

=cut

sub flatten_object
{
	my ( $self, $fields ) = @_;
	my @protected_fields = qw( password );

	my %data = ();
	foreach my $field ( @$fields )
	{
		if ( scalar( grep { $_ eq $field } @protected_fields ) != 0 )
		{
			croak "The fields '$field' is protected and cannot be added to the flattened copy";
		}
		elsif ( substr( $field, 0, 1 ) eq '_' )
		{
			croak "The field '$field' is hidden and cannot be added to the flattened copy";
		}
		elsif ( $field eq 'id' )
		{
			if ( defined( $self->get_info('primary_key_name') ) )
			{
				$data{'id'} = $self->id();
			}
			else
			{
				croak "Requested adding ID to the list of fields, but the class doesn't define a primary key name";
			}
		}
		else
		{
			$data{ $field } = $self->{ $field };
		}
	}

	return \%data;
}


=head2 reload()

Reload the content of the current object. This always skips the cache.

	$book->reload();

=cut

sub reload
{
	my ( $self ) = @_;

	# Make sure we were passed an object.
	croak 'This method can only be called on an object'
		if !Data::Validate::Type::is_hashref( $self );

	my $class = ref( $self );

	croak 'The object is not blessed with a class name'
		if !defined( $class ) || ( $class eq '' );

	croak "The class '$class' doesn't allow calling \$class->new()"
		if ! $class->can('new');

	# Verify that we can reload the object.
	croak 'Cannot reload an object for which a primary key name has not been defined at the class level.'
		if ! defined( $self->get_info('primary_key_name') );
	croak 'Cannot reload an object with no ID value for its primary key'
		if ! defined( $self->id() );

	# Retrieve a fresh version using the object ID.
	my $id = $self->id();
	my $fresh_object = $class->new(
		{ id => $self->id() },
		skip_cache => 1,
	);

	croak "Could not retrieve the row in the database corresponding to the current object using ID '$id'"
		if ! defined( $fresh_object );

	# Keep the memory location intact.
	%{ $self } = %{ $fresh_object };

	return;
}


=head2 retrieve_list()

Return an arrayref of objects matching all the criteria passed.

This method supports the following filtering criteria in a hashref passed as
first argument:

=over 4

=item * id

An ID or an arrayref of IDs corresponding to the primary key.

	# Retrieve books with ID 1.
	my $books = My::Model::Book->retrieve_list(
		{
			id => 1,
		}
	);

	# Retrieve books with IDs 1, 2 or 3.
	my $books = My::Model::Book->retrieve_list(
		{
			id => [ 1, 2, 3 ]
		}
	);

=item * Field names

A scalar value or an arrayref of values corresponding to a field listed in
C<static_class_info()> under either C<filtering_fields> or C<unique_fields>.

	# Retrieve books for an author.
	my $books = My::Model::Book->retrieve_list(
		{
			author_id => 12,
		}
	);

	# Retrieve books by ISBN.
	my $books = My::Model::Book->retrieve_list(
		{
			isbn =>
			[
				'9781449313142',
				'9781449393090',
			]
		}
	);

=back

Note that you can combine filters (which is the equivalent of AND in SQL) in
that hashref:

	# Retrieve books by ISBN for a specific author.
	my $books = My::Model::Book->retrieve_list(
		{
			isbn      =>
			[
				'9781449313142',
				'9781449393090',
			],
			author_id => 12,
		}
	);

Filters as discussed above, imply an equality between the field and the values. For instance, in the last example,
the request could be written as "Please provide a list of books with author_id equal to 12, which also have an
ISBN equal to 9781449313142 or an ISBN equal to 9781449393090".

If you wish to request records using some other operator than equals, you can create a request similar to the following:

	# Retrieve books for a specific author with ISBNs starting with a certain pattern.
	my $books = My::Model::Book->retrieve_list(
		{
			isbn      =>
			{
				operator => 'like',
				value => [ '9781%' ],
			},
			author_id => 12,
		}
	);

The above example could be written as "Please provide a list of books with author_id equal to 12, which also have
an ISBN starting with 9781".

Valid operators include:

	* =
	* not
	* <=
	* >=
	* <
	* >
	* between
	* null
	* not_null
	* like
	* not_like

This method also supports the following optional arguments, passed in a hash
after the filtering criteria above-mentioned:

=over 4

=item * dbh

Retrieve the data against a different database than the default one specified
in C<static_class_info>.

=item * order_by

Specify an ORDER BY clause to sort the objects returned.

	my $books = My::Model::Book->retrieve_list(
		{
			author_id => 12,
		},
		order_by => 'books.name ASC',
	);

=item * limit

Limit the number of objects to return.

	# Get 10 books from author #12.
	my $books = My::Model::Book->retrieve_list(
		{
			author_id => 12,
		},
		limit => 10,
	);

=item * query_extensions

Add joins and support different filtering criteria:

=over 8

=item * where_clauses

An arrayref of clauses to add to WHERE.

=item * where_values

An arrayref of values corresponding to the clauses.

=item * joins

A string specifying JOIN statements.

=item * joined_fields

A string of extra fields to add to the SELECT.

=back

	my $books = My::Model::Book->retrieve_list(
		{
			id => [ 1, 2, 3 ],
		},
		query_extensions =>
		{
			where_clauses => [ 'authors.name = ?' ],
			where_values  => [ [ 'Randal L. Schwartz' ] ],
			joins         => 'INNER JOIN authors USING (author_id)',
			joined_fields => 'authors.name AS _author_name',
		}
	);

=item * pagination

Off by default. Paginate the results. You can control the pagination options
by setting this to the following hash, with each key being optional and falling
back to the default if you omit it:

	my $books = My::Model::Book->retrieve_list(
		{},
		allow_all  => 1,
		pagination =>
		{
			# The number of results to retrieve.
			per_page    => $per_page,
			# Number of the page of results to retrieve. If you have per_page=10
			# and page=2, then this would retrieve rows 10-19 from the set of
			# matching rows.
			page        => $page,
		}
	);

Additionally, pagination can be set to '1' instead of {} and then the default
options will be used.

More pagination information is then returned in list context:

	my ( $books, $pagination ) = My::Model::Book->retrieve_list( ... );

With the following pagination information inside C<$pagination>:

	{
		# The total number of rows matching the query.
		total_count => $total_count,
		# The current page being returned.
		page        => $page,
		# The total number of pages to display the matching rows.
		page_max    => $page_max,
		# The number of rows displayed per page.
		per_page    => $per_page,
	}

=item * lock (default 0)

Add a lock to the rows retrieved.

	my $books = My::Model::Book->retrieve_list(
		{
			id => [ 1, 2, 3 ],
		},
		lock => 1,
	);

=item * allow_all (default 0)

Retrieve all the rows in the table if no criteria is passed. Off by
default to prevent retrieving large tables at once.

	# All the books!
	my $books = My::Model::Book->retrieve_list(
		{},
		allow_all => 1,
	);

=item * show_queries (default 0)

Set to '1' to see in the logs the queries being performed.

	my $books = My::Model::Book->retrieve_list(
		{
			id => [ 1, 2, 3 ],
		},
		show_queries => 1,
	);

=item * allow_subclassing (default 0)

By default, C<retrieve_list()> cannot be subclassed to prevent accidental
infinite recursions and breaking the cache features provided by NinjaORM.
Typically, if you want to add functionality to how retrieving a group of
objects works, you will want to modify C<retrieve_list_nocache()> instead.

If you really need to subclass C<retrieve_list()>, you will then need to
set C<allow_subclassing> to C<1> in subclassed method's call to its parent,
to indicate that you've carefully considered the impact of this and that it
is safe.

=item * select_fields / exclude_fields (optional)

By default, C<retrieve_list()> will select all the fields that exist on the
table associated with the class. In some rare cases, it is however desirable to
either select only or to exclude explicitely some fields from the table, and
you can pass an arrayref with C<select_fields> and C<exclude_fields>
(respectively) to specify those.

Important cache consideration: when this option is used, the cache will be used
to retrieve objects without polling the database when possible, but any objects
retrieved from the database will not be stashed in the cache as they will not
have the complete information for that object. If you have other
C<retrieve_list()> calls warming the cache this most likely won't be an issue,
but if you exclusively run C<retrieve_list()> calls with C<select_fields> and
C<exclude_fields>, then you may be better off creating a view and tieing the
class to that view.

	# To display an index of our library, we want all the book properties but not
	# the book content, which is a huge field that we won't use in the template.
	my $books = My::Model::Book->retrieve_list(
		{},
		allow_all => 1,
		exclude_fields => [ 'full_text' ],
	);

=back

=cut

sub retrieve_list
{
	my ( $class, $filters, %args ) = @_;
	my $allow_subclassing = delete( $args{'allow_subclassing'} ) || 0;

	# Check caller and prevent calls from a subclass' retrieve_list().
	if ( !$allow_subclassing )
	{
		my $subroutine = (caller(1))[3];
		if ( defined( $subroutine ) )
		{
			$subroutine =~ s/^.*:://;
			croak(
				'You have subclassed retrieve_list(), which is not allowed to prevent infinite recursions. ' .
				'You most likely want to subclass retrieve_list_nocache() instead.'
			) if $subroutine eq 'retrieve_list';
		}
	}

	my $any_cache_time = $class->get_info('list_cache_time') || $class->get_info('object_cache_time');
	return defined( $any_cache_time ) && !$args{'skip_cache'} && !$args{'lock'}
		? $class->retrieve_list_cache( $filters, %args )
		: $class->retrieve_list_nocache( $filters, %args );
}


=head1 ACCESSORS


=head2 get_cache_key_field()

Return the name of the field that should be used in the cache key.

	my $cache_time = $class->cache_key_field();
	my $cache_time = $object->cache_key_field();

=cut

sub get_cache_key_field
{
	my ( $self ) = @_;

	my $cache_key_field = $self->cached_static_class_info()->get('cache_key_field');

	# If the subclass specifies a field to use for the cache key name, use it.
	# Otherwise, we fall back on the primary key if it exists.
	return defined( $cache_key_field )
		? $cache_key_field
		: $self->get_info('primary_key_name');
}


=head2 get_default_dbh()

WARNING: this method will be removed soon. Use C<get_info('default_dbh')> instead.

Return the default database handle to use with this class.

	my $default_dbh = $class->get_default_dbh();
	my $default_dbh = $object->get_default_dbh();

=cut

sub get_default_dbh
{
	my ( $self ) = @_;

	carp "get_default_dbh() has been deprecated, please change the method call to get_info('default_dbh')";

	return $self->get_info('default_dbh');
}


=head2 get_filtering_fields()

Returns the fields that can be used as filtering criteria in retrieve_list().

Notes:

=over 4

=item * Does not include the primary key.

=item * Includes unique fields.

	my $filtering_fields = $class->get_filtering_fields();
	my $filtering_fields = $object->get_filtering_fields();

=back

=cut

sub get_filtering_fields
{
	my ( $self ) = @_;

	my %fields = (
		map { $_ => undef }
		(
			@{ $self->cached_static_class_info()->get('filtering_fields') },
			@{ $self->cached_static_class_info()->get('unique_fields') },
		)
	);
	return [ keys %fields ];
}


=head2 get_info()

Return cached static class information for the current object or class.

	my $info = $class->get_info();
	my $info = $object->get_info();

=cut

sub get_info {
	my ( $self, $key ) = @_;

	return $self->cached_static_class_info()->get( $key );
}


=head2 get_list_cache_time()

WARNING: this method will be removed soon. Use C<get_info('list_cache_time')>
instead.

Return the duration for which a list of objects of the current class can be
cached.

	my $list_cache_time = $class->list_cache_time();
	my $list_cache_time = $object->list_cache_time();

=cut

sub get_list_cache_time
{
	my ( $self ) = @_;

	carp "get_list_cache_time() has been deprecated, please change the method call to get_info('list_cache_time')";

	return $self->get_info('list_cache_time');
}


=head2 get_memcache()

WARNING: this method will be removed soon. Use C<get_info('memcache')> instead.

Return the memcache object to use with this class.

	my $memcache = $class->get_memcache();
	my $memcache = $object->get_memcache();

=cut

sub get_memcache
{
	my ( $self ) = @_;

	carp "get_memcache() has been deprecated, please change the method call to get_info('memcache')";

	return $self->get_info('memcache');
}


=head2 get_object_cache_time()

WARNING: this method will be removed soon. Use C<get_info('object_cache_time')>
instead.

Return the duration for which an object of the current class can be cached.

	my $object_cache_time = $class->get_object_cache_time();
	my $object_cache_time = $object->get_object_cache_time();

=cut

sub get_object_cache_time
{
	my ( $self ) = @_;

	carp "get_object_cache_time() has been deprecated, please change the method call to get_info('object_cache_time')";

	return $self->get_info('object_cache_time');
}


=head2 get_primary_key_name()

WARNING: this method will be removed soon. Use C<get_info('primary_key_name')> instead.

Return the underlying primary key name for the current class or object.

	my $primary_key_name = $class->get_primary_key_name();
	my $primary_key_name = $object->get_primary_key_name();

=cut

sub get_primary_key_name
{
	my ( $self ) = @_;

	carp "get_primary_key_name() has been deprecated, please change the method call to get_info('primary_key_name')";

	return $self->get_info('primary_key_name');
}


=head2 get_readonly_fields()

WARNING: this method will be removed soon. Use C<get_info('readonly_fields')> instead.

Return an arrayref of fields that cannot be modified via C<set()>, C<update()>,
or C<insert()>.

	my $readonly_fields = $class->get_readonly_fields();
	my $readonly_fields = $object->get_readonly_fields();

=cut

sub get_readonly_fields
{
	my ( $self ) = @_;

	carp "get_readonly_fields() has been deprecated, please change the method call to get_info('readonly_fields')";

	return $self->get_info('readonly_fields');
}


=head2 get_table_name()

WARNING: this method will be removed soon. Use C<get_info('table_name')> instead.

Returns the underlying table name for the current class or object.

	my $table_name = $class->get_table_name();
	my $table_name = $object->get_table_name();

=cut

sub get_table_name
{
	my ( $self ) = @_;

	carp "get_table_name() has been deprecated, please change the method call to get_info('table_name')";

	return $self->get_info('table_name');
}


=head2 get_unique_fields()

WARNING: this method will be removed soon. Use C<get_info('unique_fields')>
instead.

Return an arrayref of fields that are unique for the underlying table.

Important: this doesn't include the primary key name. To retrieve the name
of the primary key, use C<$class->primary_key_name()>

	my $unique_fields = $class->get_unique_fields();
	my $unique_fields = $object->get_unique_fields();

=cut

sub get_unique_fields
{
	my ( $self ) = @_;

	carp "get_unique_fields() has been deprecated, please change the method call to get_info('unique_fields')";

	return $self->get_info('unique_fields');
}


=head2 has_created_field()

WARNING: this method will be removed soon. Use C<get_info('has_created_field')>
instead.

Return a boolean to indicate whether the underlying table has a 'created'
field.

	my $has_created_field = $class->has_created_field();
	my $has_created_field = $object->has_created_field();

=cut

sub has_created_field
{
	my ( $self ) = @_;

	carp "has_created_field() has been deprecated, please change the method call to get_info('has_created_field')";

	return $self->get_info('has_created_field');
}


=head2 has_modified_field()

WARNING: this method will be removed soon. Use C<get_info('has_modified_field')> instead.

Return a boolean to indicate whether the underlying table has a 'modified'
field.

	my $has_modified_field = $class->has_modified_field();
	my $has_modified_field = $object->has_modified_field();

=cut

sub has_modified_field
{
	my ( $self ) = @_;

	carp "has_modified_field() has been deprecated, please change the method call to get_info('has_modified_field')";

	return $self->get_info('has_modified_field');
}


=head2 id()

Return the value associated with the primary key for the current object.

	my $id = $object->id();

=cut

sub id
{
	my ( $self ) = @_;

	my $primary_key_name = $self->get_info('primary_key_name');
	return defined( $primary_key_name )
		? $self->{ $primary_key_name }
		: undef;
}


=head2 is_verbose()

Return if verbosity is enabled.

This method supports two types of verbosity:

=over 4

=item * general verbosity

Called with no argument, this returns whether code in general will be verbose.

	$log->debug( 'This is verbose' )
		if $class->is_verbose();
	$log->debug( 'This is verbose' )
		if $object->is_verbose();

=item * verbosity for a specific type of operations

Called with a specific type of operations as first argument, this returns
whether that type of operations will be verbose.

	$log->debug( 'Describe cache operation' )
		if $class->is_verbose( $operation_type );
	$log->debug( 'Describe cache operation' )
		if $object->is_verbose( $operation_type );

Currently, the following types of operations are supported:

=over 8

=item * 'cache_operations'

=back

=back

=cut

sub is_verbose
{
	my ( $self, $specific_area ) = @_;

	my $cached_static_class_info = $self->cached_static_class_info();

	if ( defined( $specific_area ) )
	{
		my $info_key = 'verbose_' . $specific_area;

		croak "'$specific_area' is not valid"
			if ! exists( $cached_static_class_info->{ $info_key } );

		return $cached_static_class_info->get( $info_key );
	}
	else
	{
		return $cached_static_class_info->get('verbose');
	}
}


=head1 CACHE RELATED METHODS


=head2 cached_static_class_info()

Return a cached version of the information retrieved by C<static_class_info()>.

	my $static_class_info = $class->cached_static_class_info();
	my $static_class_info = $object->cached_static_class_info();

=cut

{
	my $CACHE = {};
	sub cached_static_class_info
	{
		my ( $self ) = @_;
		my $class = ref( $self ) || $self;

		$CACHE->{ $class } ||= $class->static_class_info();

		return $CACHE->{ $class }
	}
}


=head2 get_table_schema()

Return the schema corresponding to the underlying table.

	my $table_schema = $class->get_table_schema();
	my $table_schema = $object->get_table_schema();

=cut

{
	my $TABLE_SCHEMAS_CACHE = {};
	sub get_table_schema
	{
		my ( $self ) = @_;
		my $class = ref( $self ) || $self;

		if ( !defined( $TABLE_SCHEMAS_CACHE->{ $class } ) )
		{
			my $dbh = $class->assert_dbh();
			my $table_name = $self->get_info('table_name');

			Class::Load::load_class( 'DBIx::NinjaORM::Schema::Table' );
			my $table_schema = DBIx::NinjaORM::Schema::Table->new(
				name => $table_name,
				dbh  => $self->assert_dbh(),
			);
			$table_schema->get_columns();
			$TABLE_SCHEMAS_CACHE->{ $class } = $table_schema;

			croak "Failed to load schema for '$table_name'"
				if !defined( $TABLE_SCHEMAS_CACHE->{ $class } );
		}

		return $TABLE_SCHEMAS_CACHE->{ $class };
	}
}


=head2 delete_cache()

Delete a key from the cache.

	my $value = $class->delete_cache( key => $key );

=cut

sub delete_cache
{
	my ( $self, %args ) = @_;
	my $key = delete( $args{'key'} );
	croak 'Invalid argument(s): ' . join( ', ', keys %args )
		if scalar( keys %args ) != 0;

	# Check parameters.
	croak 'The parameter "key" is mandatory'
		if !defined( $key ) || $key !~ /\w/;

	my $memcache = $self->get_info('memcache');
	return undef
		if !defined( $memcache );

	return $memcache->delete( $key );
}


=head2 get_cache()

Get a value from the cache.

	my $value = $class->get_cache( key => $key );

=cut

sub get_cache
{
	my ( $self, %args ) = @_;
	my $key = delete( $args{'key'} );
	croak 'Invalid argument(s): ' . join( ', ', keys %args )
		if scalar( keys %args ) != 0;

	# Check parameters.
	croak 'The parameter "key" is mandatory'
		if !defined( $key ) || $key !~ /\w/;

	my $memcache = $self->get_info('memcache');
	return undef
		if !defined( $memcache );

	return $memcache->get( $key );
}


=head2 get_object_cache_key()

Return the name of the cache key for an object or a class, given a field name
on which a unique constraint exists and the corresponding value.

	my $cache_key = $object->get_object_cache_key();
	my $cache_key = $class->get_object_cache_key(
		unique_field => $unique_field,
		value        => $value,
	);

=cut

sub get_object_cache_key
{
	my ( $self, %args ) = @_;
	my $unique_field = delete( $args{'unique_field'} );
	my $value = delete( $args{'value'} );

	# Retrieve the field we'll use to create the cache key.
	my $cache_key_field = $self->get_cache_key_field();
	croak 'No cache key found for class'
		if !defined( $cache_key_field );

	my $table_name = $self->get_info('table_name');
	if ( defined( $unique_field ) )
	{
		if ( !defined( $value ) )
		{
			$log->debugf(
				"Passed unique field '%s' without a corresponding value for "
				. "table '%s', cannot determine cache key",
				$unique_field,
				$table_name,
			);
			return;
		}

		# 'id' is only an alias and needs to be expanded to its actual name.
		$unique_field = $self->get_info('primary_key_name')
			if $unique_field eq 'id';
	}
	else
	{
		# If no unique field was passed, use the $cache_key_field field and its
		# corresponding value.
		if ( Data::Validate::Type::is_hashref( $self ) )
		{
			$unique_field = $cache_key_field;
			$value = $self->{ $unique_field };

			unless ( defined( $value ) )
			{
				$log->debugf(
					"Trying to use field '%s' on table '%s' to generate "
					. "a cache key, but the value for that field on the "
					. "object is undef",
					$cache_key_field,
					$table_name,
				);
				return;
			}
		}
		else
		{
			$log->debug(
				"If you don't specify a unique field and value, you need to "
				. "call this function on an object"
			);
			return;
		}
	}

	# If the unique field passed doesn't match what the cache key is, we need
	# to do a database lookup to find out the corresponding cache key.
	my $cache_key_value;
	if ( $unique_field ne $cache_key_field )
	{
		my $dbh = $self->assert_dbh();

		$cache_key_value = $dbh->selectrow_arrayref(
			sprintf(
				q|
					SELECT %s
					FROM %s
					WHERE %s = ?
				|,
				$dbh->quote_identifier( $cache_key_field ),
				$dbh->quote_identifier( $table_name ),
				$dbh->quote_identifier( $unique_field ),
			),
			{},
			$value,
		);

		$cache_key_value = defined( $cache_key_value ) && scalar( @$cache_key_value ) != 0
			? $cache_key_value->[0]
			: undef;

		unless ( defined( $cache_key_value ) )
		{
			$log->debugf(
				"Cache miss for unique field '%s' and value '%s' on table "
				. "'%s', cannot generate cache key.",
				$unique_field,
				$value,
				$table_name,
			) if $self->is_verbose();
			return;
		}
	}
	else
	{
		$cache_key_value = $value;
	}

	return lc( 'object|' . $table_name . '|' . $cache_key_field . '|' . $cache_key_value );
}


=head2 invalidate_cached_object()

Invalidate the cached copies of the current object across all the unique
keys this object can be referenced with.

	$object->invalidate_cached_object();

=cut

sub invalidate_cached_object
{
	my ( $self ) = @_;

	my $primary_key_name = $self->get_info('primary_key_name');
	if ( defined( $primary_key_name ) )
	{
		my $cache_key = $self->get_object_cache_key(
			unique_field => 'id',
			value        => $self->id(),
		);
		$self->delete_cache( key => $cache_key )
			if defined( $cache_key );
	}

	foreach my $field ( @{ $self->get_info('unique_fields') // [] } )
	{
		# If the object has no value for the unique field, it wasn't
		# cached for this key/value pair and we can't build a cache key
		# for it anyway, so we just skip to the next unique field.
		next unless defined( $self->{ $field } );

		my $cache_key = $self->get_object_cache_key(
			unique_field => $field,
			value        => $self->{ $field },
		);
		$self->delete_cache( key => $cache_key )
			if defined( $cache_key );
	}

	return 1;
}


=head2 retrieve_list_cache()

Dispatch of retrieve_list() when objects should be retrieved from the cache.

See C<retrieve_list()> for the parameters this method accepts.

=cut

sub retrieve_list_cache ## no critic (Subroutines::ProhibitExcessComplexity)
{
	my ( $class, $filters, %args ) = @_;
	my $list_cache_time = $class->get_info('list_cache_time');
	my $object_cache_time = $class->get_info('object_cache_time');
	my $primary_key_name = $class->get_info('primary_key_name');

	# Create a unique cache key.
	my $list_cache_keys = [];
	foreach my $filter ( keys %$filters )
	{
		# Force all arguments into lower case for purposes of caching.
		push( @$list_cache_keys, [ lc( $filter ), $filters->{ $filter } ] );
	}
	foreach my $arg ( sort keys %args )
	{
		# Those arguments don't have an impact on the filters to IDs translation,
		# so we can exclude them from the unique cache key.
		my $has_impact = $RETRIEVE_LIST_VALID_ARGUMENTS->{ $arg };
		croak "The argument '$arg' is not valid"
			if !defined( $has_impact );
		next if !$has_impact;

		# Force all arguments into lower case for purposes of caching.
		push( @$list_cache_keys, [ lc( $arg ), $args{ $arg } ] );
	}

	my $list_cache_key = MIME::Base64::encode_base64( Storable::freeze( $list_cache_keys ) );
	chomp( $list_cache_key );
	my $list_cache_key_sha1 = Digest::SHA1::sha1_base64( $list_cache_key );

	# Find out if the parameters are searching by ID or using a unique field.
	my $search_field;
	my $list_of_search_values;
	foreach my $field ( 'id', @{ $class->get_info('unique_fields') // [] } )
	{
		next
			unless exists( $filters->{ $field } );

		$search_field = $field;

		$list_of_search_values = Data::Validate::Type::filter_arrayref( $filters->{ $field } )
			// [ $filters->{ $field } ];
	}

	# If we're searcing by ID or unique field, those are how the objects are
	# cached so we already know how to retrieve them from the object cache.
	# If we're searching by anything else, then we maintain a "list cache",
	# which associates retrieve_list() args with the resulting IDs.
	my $pagination;
	my $list_cache_used = 0;
	if ( !defined( $search_field ) )
	{
		# Test if we have a corresponding list of IDs in the cache.
		my $cache = $class->get_cache( key => $list_cache_key_sha1 );

		if ( defined( $cache ) )
		{
			my $cache_content = Storable::thaw( MIME::Base64::decode_base64( $cache ) );
			my ( $original_list_cache_key, $original_pagination, $original_search_field, $original_list_of_ids ) = @{ Data::Validate::Type::filter_arrayref( $cache_content ) // [] };

			# We need to use SHA1 due to the limitation on the length of memcache keys
			# (we can't just cache $cache_key).
			# However, there is a very small risk of collision so we check here that
			# the cache key stored inside the cache entry is the same.
			if ( $original_list_cache_key eq $list_cache_key )
			{
				$list_of_search_values = $original_list_of_ids;
				$pagination = $original_pagination;
				$search_field = $original_search_field;
				$list_cache_used = 1;
			}
		}
	}

	my $cached_objects = {};
	my $objects;
	if ( !$args{'lock'} && defined( $list_of_search_values ) )
	{
		$log->debug( "Using values (unique/IDs) from the list cache" )
			if $class->is_verbose('cache_operations');

		# If we're not trying to lock the underlying rows, and we have a list of
		# IDs from the cache, we try to get the objects from the object cache.
		my $objects_to_retrieve_from_database = {};
		foreach my $search_value ( @$list_of_search_values )
		{
			my $object_cache_key = $class->get_object_cache_key(
				unique_field => $search_field eq 'id'
					? $primary_key_name
					: $search_field,
				value        => $search_value,
			);

			my $object = defined( $object_cache_key )
				? $class->get_cache( key => $object_cache_key )
				: undef;

			if ( defined( $object ) )
			{
				$log->debugf(
					"Retrieved '%s' from cache.",
					$object_cache_key,
				) if $class->is_verbose('cache_operations');

				$object->{'_debug'}->{'object_cache_used'} = 1;

				my $hash_key = lc(
					$search_field eq 'id'
						? $object->id()
						: $object->get( $search_field )
				);

				$cached_objects->{ $hash_key } = $object;
			}
			else
			{
				$log->debugf(
					"'%s' not found in the cache.",
					$object_cache_key,
				) if $class->is_verbose('cache_operations');

				$objects_to_retrieve_from_database->{ lc( $search_value ) } = $object_cache_key;
			}
		}

		# If we have any ID we couldn't get an object for from the cache, we now
		# go to the database.
		if ( scalar( keys %$objects_to_retrieve_from_database ) != 0 )
		{
			$log->debug(
				"The following objects are not cached and need to be retrieved from the database: %s",
				join( ', ', keys %$objects_to_retrieve_from_database ),
			) if $class->is_verbose('cache_operations');

			# We don't want to pass %args, which has a lot of information that may
			# actually conflict with what we're trying to do here. However, some of
			# the arguments are important, such as 'dbh' to connect to the correct
			# database. We filter here the relevant arguments.
			my %local_args =
				map { $_ => $args{ $_ } }
				grep { defined( $args{ $_ } ) }
				qw( dbh show_queries exclude_fields select_fields );

			$objects = $class->retrieve_list_nocache(
				{
					$search_field => [ keys %$objects_to_retrieve_from_database ],
				},
				%local_args,
			);
		}

		# Indicate that we've used the list cache to retrieve the list of object
		# IDs.
		if ( $list_cache_used )
		{
			foreach my $object ( values %$cached_objects, @{ $objects // [] } )
			{
				$object->{'_debug'}->{'list_cache_used'} = 1;
			}
		}
	}
	else
	{
		# If we don't have a list of IDs, we need to go to the database via
		# retrieve_list_nocache() to get the objects.
		( $objects, $pagination ) = $class->retrieve_list_nocache(
			$filters,
			%args,
		);

		# Set the list cache.
		my $list_cache_ids = [ map { $_->id() } @$objects ];

		$log->debugf(
			"Adding key '%s' to the list cache, with the following IDs: %s",
			$list_cache_key,
			join( ', ', @$list_cache_ids ),
		) if $class->is_verbose('cache_operations');

		$class->set_cache(
			key         => $list_cache_key_sha1,
			value       => MIME::Base64::encode_base64(
				Storable::freeze(
					[
						$list_cache_key,
						$pagination,
						'id',
						$list_cache_ids,
					]
				)
			),
			expire_time => $list_cache_time,
		);
	}

	# For cache purposes, we use the search field if it is available (as it's
	# either the primary key or a unique field), and we fall back on 'id'
	# which exists on all objects as a primary key shortcut.
	my $cache_field = $search_field // 'id';

	# Cache the objects.
	my $database_objects = {};
	foreach my $object ( @$objects )
	{
		my $hash_key = lc(
			$cache_field eq 'id'
				? $object->id()
				: $object->get( $cache_field )
		);

		$database_objects->{ $hash_key } = $object;

		# If the caller forced excluding fields, we can't cache the objects here.
		# Otherwise, we would serve incomplete objects the next time a caller
		# requests objects without specifying the same excluded fields.
		# Same goes for explicit fields restrictions.
		next
			if exists( $object->{'_excluded_fields'} ) || exists( $object->{'_selected_fields'} );

		my $object_cache_key = $cache_field eq 'id'
			? $object->get_object_cache_key()
			: $object->get_object_cache_key(
				unique_field => $cache_field,
				value        => $object->get( $cache_field ),
			);

		next if !defined( $object_cache_key );

		$object->{'_debug'}->{'cache_expires'} = time() + $object_cache_time;

		$log->debugf(
			"Set object cache for key '%s'.",
			$object_cache_key,
		) if $class->is_verbose('cache_operations');

		$class->set_cache(
			key         => $object_cache_key,
			value       => $object,
			expire_time => $object_cache_time,
		);
	}

	# Make sure the objects are sorted.
	my $sorted_objects;
	if ( defined( $list_of_search_values ) )
	{
		# If we've been using a list of IDs from the cache, we need to merge
		# the objects and sort them.
		$sorted_objects = [];
		foreach my $search_value ( @$list_of_search_values )
		{
			if ( exists( $cached_objects->{ lc( $search_value ) } ) )
			{
				push( @$sorted_objects, $cached_objects->{ lc( $search_value ) } );
			}
			elsif ( exists( $database_objects->{ lc( $search_value ) } ) )
			{
				push( @$sorted_objects, $database_objects->{ lc( $search_value ) } );
			}
			else
			{
				$log->debugf(
					'Failed to retrieve object for %s=%s',
					$cache_field,
					$search_value,
				);
			}
		}
	}
	else
	{
		# Otherwise, $object comes from the database and is already sorted by
		# retrieve_list_nocache().
		$sorted_objects = $objects;
	}

	# Return the objects, taking into account whether pagination is requested.
	if ( wantarray && defined( $args{'pagination'} ) )
	{
		return ( $sorted_objects, $pagination );
	}
	else
	{
		return $sorted_objects;
	}
}


=head2 set_cache()

Set a value into the cache.

	$class->set_cache(
		key         => $key,
		value       => $value,
		expire_time => $expire_time,
	);

=cut

sub set_cache
{
	my ( $self, %args ) = @_;
	my $key = delete( $args{'key'} );
	my $value = delete( $args{'value'} );
	my $expire_time = delete( $args{'expire_time'} );
	croak 'Invalid argument(s): ' . join( ', ', keys %args )
		if scalar( keys %args ) != 0;

	# Check parameters.
	croak 'The argument "key" is mandatory'
		if !defined( $key ) || $key !~ /\w/;
	croak 'The argument "value" is mandatory'
		if !defined( $value );

	my $memcache = $self->get_info('memcache');
	return
		if !defined( $memcache );

	$memcache->set( $key, $value, $expire_time )
		|| $log->errorf( "Failed to set cache with key '%s'.", $key );

	return;
}


=head1 INTERNAL METHODS

Those methods are used internally by L<DBIx::NinjaORM>, you should not subclass
them.


=head2 assert_dbh()

Assert that there is a database handle, either a specific one passed as first
argument to this function (if defined) or the default one specified via
C<static_class_info()>, and return it.

	my $dbh = $class->assert_dbh();
	my $dbh = $object->assert_dbh();

	my $dbh = $class->assert_dbh( $custom_dbh );
	my $dbh = $object->assert_dbh( $custom_dbh );

Note that this method also supports coderefs that return a C<DBI::db> object
when evaluated. That way, if no database connection is needed when running the
code, no connection needs to be established.

=cut

sub assert_dbh
{
	my ( $class, $specific_dbh ) = @_;

	my ( $dbh, $type );
	if ( defined( $specific_dbh ) )
	{
		$dbh = $specific_dbh;
		$type = 'specified';
	}
	else
	{
		$dbh = $class->get_info('default_dbh');
		$type = 'default';
	}

	$dbh = $dbh->()
		if Data::Validate::Type::is_coderef( $dbh );

	croak "The $type database handle is not a valid DBI::db object (" . ref( $dbh ) . ')'
		if !Data::Validate::Type::is_instance( $dbh, class => 'DBI::db' );

	return $dbh;
}


=head2 build_filtering_clause()

Create a filtering clause using the field, operator and values passed.

	my ( $clause, $clause_values ) = $class->build_filtering_clause(
		field    => $field,
		operator => $operator,
		values   => $values,
	);

=cut

sub build_filtering_clause
{
	my ( $class, %args ) = @_;
	my $field = $args{'field'};
	my $operator = $args{'operator'};
	my $values = $args{'values'};

	my $clause;
	my $clause_values = [ $values ];

	# Quote the field name.
	my $dbh = $class->assert_dbh();
	my $quoted_field = join( '.', map { $dbh->quote_identifier( $_ ) } split( /\./, $field ) );

	croak 'A field name is required'
		if !defined( $field ) || $field eq '';

	# Between is a special case where values are an arrayref of a specific size.
	if ( $operator eq 'between' ) ## no critic (ControlStructures::ProhibitCascadingIfElse)
	{
		unless ( defined( $values ) && Data::Validate::Type::is_arrayref( $values )  && scalar( @$values ) == 2 )
		{
			croak '>between< requires two values to be passed as an arrayref';
		}

		$clause = "$quoted_field BETWEEN ? AND ?";
		$clause_values = $values;
	}
	# 'null' is also a special case with no values.
	elsif ( $operator eq 'null' )
	{
		$clause = "$quoted_field IS NULL";
		$clause_values = [];
	}
	# 'not_null' is also a special case with no values.
	elsif ( $operator eq 'not_null' )
	{
		$clause = "$quoted_field IS NOT NULL";
		$clause_values = [];
	}
	# More than one value passed.
	elsif ( Data::Validate::Type::is_arrayref( $values ) )
	{
		if ( $operator eq '=' ) ## no critic (ControlStructures::ProhibitCascadingIfElse)
		{
			$clause = "$quoted_field IN (" . join( ', ', ( ( '?' ) x scalar( @$values ) ) ) . ")";
			$clause_values = $values;
		}
		elsif ( $operator eq 'not' )
		{
			$clause = "$quoted_field NOT IN (" . join( ', ', ( ( '?' ) x scalar( @$values ) ) ) . ")";
			$clause_values = $values;
		}
		elsif ( $operator eq '>' || $operator eq '>=' )
		{

			# List::Util::max() really hates undefined elements and will warn
			# loudly at each one it encounters. So, grep them out first.
			my $max = List::Util::max( grep { defined( $_ ) } @$values );
			if ( defined( $max ) )
			{
				$clause = "$quoted_field $operator ?";
				$clause_values = [ $max ];
			}
			else
			{
				croak 'Could not find max of the following list: ' . dumper( $values );
			}
		}
		elsif ( $operator eq '<' || $operator eq '<=' )
		{
			# List::Util::max() really hates undefined elements and will warn
			# loudly at each one it encounters. So, grep them out first.
			my $min = List::Util::min( grep { defined( $_ ) } @$values );
			if ( defined( $min ) )
			{
				$clause = "$quoted_field $operator ?";
				$clause_values = [ $min ];
			}
			else
			{
				croak 'Could not find min of the following list: ' . dumper( $values );
			}
		}
		elsif ( $operator eq 'like' )
		{
			# Permit more than one like clause on the same field.
			$clause = "$quoted_field LIKE ? OR " x scalar @{ $values };
			$clause = substr( $clause, 0, -4 );
			$clause_values = $values;
		}
		elsif ( $operator eq 'not_like' )
		{
			# Permit more than one like clause on the same field.
			$clause = "$quoted_field NOT LIKE ? AND " x scalar @{ $values };
			$clause = substr( $clause, 0, -5 );
			$clause_values = $values;
		}
		# Only one value passed.
		else
		{
			croak "The operator '$operator' is not implemented";
		}
	}
	else
	{
		$operator = '!='
			if $operator eq 'not';

		$clause = "$quoted_field $operator ?";
	}

	return ( $clause, $clause_values );
}


=head2 parse_filtering_criteria()

Helper function that takes a list of fields and converts them into where
clauses and values that can be used by retrieve_list().

	my ( $where_clauses, $where_values, $filtering_field_keys_passed ) =
		@{
			$class->parse_filtering_criteria(
				\%filtering_criteria
			)
		};

$filtering_field_keys_passed indicates whether %values had keys matching at
least one element of @field. This allows detecting whether any filtering
criteria was passed, even if the filtering criteria do not result in WHERE
clauses being returned.

=cut

sub parse_filtering_criteria
{
	my ( $class, $filters ) = @_;

	# Check the arguments.
	if ( !Data::Validate::Type::is_hashref( $filters ) )
	{
		my $error = "The first argument must be a hashref of filtering criteria";
		$log->error( $error );
		croak $error;
	};

	# Build the list of filtering fields we allow.
	my $filtering_fields =
	{
		map { $_ => 1 }
		@{ $class->get_filtering_fields() || [] }
	};

	my $primary_key_name = $class->get_info('primary_key_name');
	if ( defined( $primary_key_name ) )
	{
		# If there's a primary key name, allow 'id' as an alias.
		$filtering_fields->{'id'} = 1;
	}

	# Check if we were passed filters we don't know how to handle. This will
	# help the calling code to detect typos or missing filtering fields in the
	# static class declaration.
	foreach my $filter ( keys %$filters )
	{
		next if defined( $filtering_fields->{ $filter } );

		croak(
			"The filtering criteria '$filter' passed to DBIx::NinjaORM->retrieve_list() " .
			"via ${class}->retrieve_list() is not handled by the superclass. It could " .
			"mean that you have a typo in the name, or that you need to add it to " .
			"the list of filtering fields in ${class}->static_class_info()."
		);
	}

	# Find the table name to prefix it to the field names when we create where
	# clauses.
	my $table_name = $class->get_info('table_name');
	croak "No table name found for the class >" . ( ref( $class ) || $class ) . "<"
		if !defined( $table_name );

	my $where_clauses = [];
	my $where_values = [];
	my $filtering_field_keys_passed = 0;
	foreach my $field ( sort keys %$filters )
	{
		# "field => undef" and "field => []" are not valid filtering
		# criteria. This prevents programming errors, by forcing the
		# use of the 'null' operator when you explicitely want to
		# test for NULL. See:
		#
		#     field =>
		#     {
		#         operator => 'null',
		#     }
		#
		next unless defined( $filters->{ $field } );
		next if Data::Validate::Type::is_arrayref( $filters->{ $field } )
			&& scalar( @{ $filters->{ $field } } ) == 0;

		# We now have a valid filtering criteria.
		$filtering_field_keys_passed = 1;

		# Add the table prefix if needed, this will prevent conflicts if the
		# main query performs JOINs.
		my $full_field_name = defined( $primary_key_name ) && ( $field eq 'id' )
			? $table_name . '.' . $primary_key_name
			: $field =~ m/\./
				? $field
				: $table_name . '.' . $field;

		# Turn the value into an array of values, if needed.
		my $values = Data::Validate::Type::is_arrayref( $filters->{ $field } )
			? $filters->{ $field }
			: [ $filters->{ $field } ];

		my @scalar_values = ();
		foreach my $block ( @$values )
		{
			if ( Data::Validate::Type::is_hashref( $block ) )
			{
				if ( !defined( $block->{'operator'} ) )
				{
					croak 'The operator is missing or not defined';
				}
				elsif ( $block->{'operator'} !~ m/^(?:=|not|<=|>=|<|>|between|null|not_null|like|not_like)$/x )
				{
					croak "The operator '$block->{'operator'}' is not a valid one. Try (=|not|<=|>=|<|>)";
				}
				elsif ( !exists( $block->{'value'} ) && $block->{'operator'} !~ /^(?:null|not_null)$/ )
				{
					croak "The value key is missing for operator '$block->{'operator'}'";
				}

				my ( $clause, $clause_values ) = $class->build_filtering_clause(
					field    => $full_field_name,
					operator => $block->{'operator'},
					values   => $block->{'value'},
				);
				push( @$where_clauses, $clause );
				push( @$where_values, $clause_values );
			}
			else
			{
				push( @scalar_values, $block );
			}
		}

		if ( scalar( @scalar_values ) != 0 )
		{
			my ( $clause, $clause_values ) = $class->build_filtering_clause(
				field    => $full_field_name,
				operator => '=',
				values   => \@scalar_values,
			);
			push( @$where_clauses, $clause );
			push( @$where_values, $clause_values );
		}
	}

	return [ $where_clauses, $where_values, $filtering_field_keys_passed ];
}


=head2 reorganize_non_native_fields()

When we retrieve fields via SELECT in retrieve_list_nocache(), by convention we use
_[table_name]_[field_name] for fields that are not native to the underlying
table that the object represents.

This method moves them to $object->{'_table_name'}->{'field_name'} for a
cleaner organization inside the object.

	$object->reorganize_non_native_fields();

=cut

sub reorganize_non_native_fields
{
	my ( $self ) = @_;

	# Move non-native fields to their own happy place.
	foreach my $field ( keys %$self )
	{
		next unless $field =~ m/^(_[^_]+)_(.*)$/;
		$self->{ $1 }->{ $2 } = $self->{ $field };
		delete( $self->{ $field } );
	}

	return;
}


=head1 BUGS

Please report any bugs or feature requests through the web interface at
L<https://github.com/guillaumeaubert/DBIx-NinjaORM/issues/new>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc DBIx::NinjaORM


You can also look for information at:

=over 4

=item * GitHub's request tracker

L<https://github.com/guillaumeaubert/DBIx-NinjaORM/issues>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/DBIx-NinjaORM>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/DBIx-NinjaORM>

=item * MetaCPAN

L<https://metacpan.org/release/DBIx-NinjaORM>

=back


=head1 AUTHOR

L<Guillaume Aubert|https://metacpan.org/author/AUBERTG>, C<< <aubertg at cpan.org> >>.


=head1 CONTRIBUTORS

=over 4

=item * L<Brian Voorhes|https://metacpan.org/author/BRETHIR>

=item * Jamie McCarthy

=item * L<Jennifer Pinkham|https://metacpan.org/author/JPINKHAM>

=item * L<Kate Kirby|https://metacpan.org/author/KATE>

=back


=head1 ACKNOWLEDGEMENTS

I originally developed this project for ThinkGeek
(L<http://www.thinkgeek.com/>). Thanks for allowing me to open-source it!

Special thanks to Kate Kirby for her help with the design of this module.


=head1 COPYRIGHT & LICENSE

Copyright 2009-2017 Guillaume Aubert.

This code is free software; you can redistribute it and/or modify it under the
same terms as Perl 5 itself.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the LICENSE file for more details.

=cut

1;
