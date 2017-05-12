package DBIx::NinjaORM::StaticClassInfo;

use 5.010;

use strict;
use warnings;

use Carp;
use Data::Validate::Type;


=head1 NAME

DBIx::NinjaORM::StaticClassInfo - Hold the configuration information for L<DBIX::NinjaORM> classes.


=head1 VERSION

Version 3.1.0

=cut

our $VERSION = '3.1.0';


=head1 DESCRIPTION

This package is used to store and retrieve defaults as well as general
information for a specific class. It allows for example indicating what table
the objects will be related to, or what database handle to use.

Here's the full list of the options that can be set or overridden:

=over 4

=item * default_dbh

The database handle to use when performing queries. The methods that interact
with the database always provide a C<dbh> argument to allow using a specific
database handle, but setting it here means you won't have to systematically
pass that argument.

	$info->{'default_dbh'} = DBI->connect(
		"dbi:mysql:[database_name]:localhost:3306",
		"[user]",
		"[password]",
	);

=item * memcache

Optionally, C<DBIx::NinjaORM> uses memcache to cache objects and queries,
in conjunction with the C<list_cache_time> and C<object_cache_time> arguments.

If you want to enable the cache features, you can set this to a valid
C<Cache::Memcached> object (or a compatible module, such as
C<Cache::Memcached::Fast>).

	$info->{'memcache'} = Cache::Memcached::Fast->new(
		{
			servers =>
			[
				'localhost:11211',
			],
		}
	);

=item * table_name

Mandatory, the name of the table that this class will be the interface for.

	# Interface with a 'books' table.
	$info->{'table_name'} = 'books';

=item * primary_key_name

The name of the primary key on the table specified with C<table_name>.

	$info->{'primary_key_name'} = 'book_id';

=item * list_cache_time

Control the list cache, which is an optional cache system in
C<retrieve_list()> to store how search criteria translate into object IDs.

By default it is disabled (with C<undef>), but it is activated by setting it to
an integer that represents the cache time in seconds.

	# Cache for 10 seconds.
	$info->{'list_cache_time'} = 10;

	# Don't cache.
	$info->{'list_cache_time'} = undef;

A good use case for this would be retrieving a list of books for a given author.
We would pass the author ID as a search criteria, and the resulting list of book
objects does not change often. Provided that you can tolerate a 1 hour delay
for a new book to show up associated with a given author, then it makes sense
to set the list_cache_time to 3600 and save most of the queries to find what
book otherwise belongs to the author.

=item * object_cache_time

Control the object cache, which is an optional cache system in
C<retrieve_list()> to store the objects returned and be able to look them up
by object ID.

By default it is disabled (with C<undef>), but it is activated by setting it to
an integer that represents the cache time in seconds.

	# Cache for 10 seconds.
	$info->{'object_cache_time'} = 10;

	# Don't cache.
	$info->{'object_cache_time'} = undef;

A good use case for this are objects that are expensive to build. You will see
more in C<retrieve_list()> on how to cache objects.

=item * unique_fields

The list of unique fields on the object.

Note: L<DBIx::NinjaORM> does not support unique indexes made of more than one
field. If you add more than one field in this arrayref, the ORM will treat them
as separate unique indexes.

	# Declare books.isbn as unique.
	$info->{'unique_fields'} = [ 'isbn' ];

	# Declare books.isbn and books.upc as unique.
	$info->{'unique_fields'} = [ 'isbn', 'upc' ];

=item * filtering_fields

The list of fields that can be used to filter on in C<retrieve_list()>.

	# Allow filtering based on the book name and author ID.
	$info->{'unique_fields'} = [ 'name', 'author_id' ];

=item * readonly_fields

The list of fields that cannot be set directly. They will be populated in
C<retrieve_list>, but you won't be able to insert / update / set them directly.

=item * has_created_field

Indicate whether the table has a field name C<created> to store the UNIX time
at which the row was created. Default: 1.

	# The table doesn't have a 'created' field.
	$info->{'has_created_field'} = 0;

=item * has_modified_field

Indicate whether the table has a field name C<modified> to store the UNIX time
at which the row was modified. Default: 1.

	# The table doesn't have a 'modified' field.
	$info->{'has_modified_field'} = 0;

=item * cache_key_field

By default, the object cache uses the primary key value to make cached objects
available to look up, but this allows specifying a different field for that
purpose.

For example, you may want to use books.isbn instead of books.book_id to cache
objects:

	$info->{'cache_key_field'} = 'isbn';

=item * verbose

Add debugging and tracing information, 0 by default.

	# Show debugging information for operations on this class.
	$info->{'verbose'} = 1;

=item * verbose_cache_operations

Add information in the logs regarding cache operations and uses.

=back


=head1 SYNOPSIS

	my $static_class_info = $class->SUPER::static_class_info();

	# Set or override information.
	$static_class_info->set(
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

	# Retrieve information.
	my $table_name = $static_class_info->get('table_name');


=head1 METHODS

=head2 new()

Create a new L<DBIx::NinjaORM::StaticClassInfo> object.

	my $static_class_info = DBIx::NinjaORM::StaticClassInfo->new();

=cut

sub new
{
	my ( $class ) = @_;

	return bless(
		{
			'default_dbh'              => undef,
			'memcache'                 => undef,
			'table_name'               => undef,
			'primary_key_name'         => undef,
			'list_cache_time'          => undef,
			'object_cache_time'        => undef,
			'unique_fields'            => [],
			'filtering_fields'         => [],
			'readonly_fields'          => [],
			'has_created_field'        => 1,
			'has_modified_field'       => 1,
			'cache_key_field'          => undef,
			'verbose'                  => 0,
			'verbose_cache_operations' => 0,
		},
		$class,
	);
}


=head2 get()

Retrieve the value of one of the configuration variables.

	my $value = $static_class_info->get( $key );

=cut

sub get
{
	my ( $self, $key ) = @_;

	croak "The key name must be defined"
		if !defined( $key );
	croak "The key '$key' is not valid"
		if !exists( $self->{ $key } );

	return $self->{ $key };
}

=head2 set()

Set values for one or more configuration variables.

	$static_class_info->set(
		{
			unique_fields    => [],
			filtering_fields => [],
			...
		}
	);

=cut

sub set ## no critic (NamingConventions::ProhibitAmbiguousNames, Subroutines::RequireArgUnpacking)
{
	croak 'The first argument passed must be a hashref'
		if !Data::Validate::Type::is_hashref( $_[1] );

	my ( $self, $values ) = @_;

	foreach my $key ( keys %$values )
	{
		croak "The key '$key' is not valid"
			if !exists( $self->{ $key } );

		$self->{ $key } = $values->{ $key };
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

	perldoc DBIx::NinjaORM::StaticClassInfo


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

Guillaume Aubert, C<< <aubertg at cpan.org> >>.


=head1 COPYRIGHT & LICENSE

Copyright 2009-2017 Guillaume Aubert.

This code is free software; you can redistribute it and/or modify it under the
same terms as Perl 5 itself.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the LICENSE file for more details.

=cut

1;
