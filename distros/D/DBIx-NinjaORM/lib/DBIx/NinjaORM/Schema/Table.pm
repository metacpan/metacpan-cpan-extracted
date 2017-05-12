package DBIx::NinjaORM::Schema::Table;

use strict;
use warnings;

use Carp;
use DBIx::Inspector;


=head1 NAME

DBIx::NinjaORM::Schema::Table - Store information about a table used by L<DBIx::NinjaORM>.


=head1 VERSION

Version 3.1.0

=cut

our $VERSION = '3.1.0';


=head1 DESCRIPTION

L<DBIx::NinjaORM::Schema::Table> currently uses L<DBIx::Inspector> to retrieve
various information about the tables used. This may however change in the
future, so this package encapsulates various functions to make it easier to
replace the dependencies and internals later if needed.


=head1 SYNOPSIS

	use DBIx::NinjaORM::Schema::Table;
	my $table_schema = DBIx::NinjaORM::Schema::Table->new(
		dbh  => $dbh,
		name => $name,
	);

	my $column_names = $table_schema->get_column_names();


=head1 METHODS

=head2 new()

Create a new DBIx::NinjaORM::Schema::Table object.

	my $table_schema = DBIx::NinjaORM::Schema::Table->new(
		dbh  => $dbh,
		name => $name,
	);

Arguments:

=over 4

=item * dbh (mandatory)

The database handle to use to access the table.

=item * name (mandatory)

The name of the table.

=back

=cut

sub new
{
	my ( $class, %args ) = @_;
	my $name = delete( $args{'name'} );
	my $dbh = delete( $args{'dbh'} );
	croak 'The following arguments are not valid: ' . join( ', ', keys %args )
		if scalar( keys %args ) != 0;

	# Check for the mandatory parameters.
	croak 'The argument "name" is mandatory'
		if !defined( $name );
	croak 'The argument "dbh" is mandatory'
		if !defined( $dbh );

	# Return a blessed object.
	return bless(
		{
			name => $name,
			dbh  => $dbh,
		},
		$class,
	);
}


=head2 get_name()

Return the table name.

	my $table_name = $table_schema->get_name();

=cut

sub get_name
{
	my ( $self ) = @_;

	return $self->{'name'};
}


=head2 get_dbh()

Return the database handle associated with the table.

	my $dbh = $table_schema->get_dbh();

=cut

sub get_dbh
{
	my ( $self ) = @_;

	return $self->{'dbh'};
}


=head2 get_column_names()

Return the name of the columns that exist in the underlying table.

	my $column_names = $table_schema->get_column_names();

=cut

sub get_column_names
{
	my ( $self ) = @_;

	my $columns = $self->get_columns();

	return [ map { $_->name() } @$columns ];
}


=head1 INTERNAL METHODS

Warning: the API for the internal methods may change in the future. Use or
subclass with caution.


=head2 get_inspector()

Return a cached L<DBIx::Inspector object>.

	my $inspector = $table_schema->get_inspector();

=cut

sub get_inspector
{
	my ( $self ) = @_;

	if ( !defined( $self->{'inspector'} ) )
	{
			$self->{'inspector'} = DBIx::Inspector->new( dbh => $self->get_dbh() );
			croak 'Failed to create the DBIx::Inspector object'
				if !defined( $self->{'inspector'} );
	}

	return $self->{'inspector'};
}


=head2 get_table()

Return the cached L<DBIx::Inspector::Table> object associated with the
underlying table.

	my $table = $table_schema->get_table();

=cut

sub get_table
{
	my ( $self ) = @_;

	if ( !defined( $self->{'table'} ) )
	{
		my $inspector = $self->get_inspector();
		$self->{'table'} = $inspector->table(
			$self->get_name()
		);

		croak 'Failed to retrieve the table object'
			if !defined( $self->{'table'} );
	}

	return $self->{'table'};
}

=head2 get_columns()

Return the cached arrayref of L<DBIx::Inspector::Column> objects corresponding
to the columns of the underlying table.

	my $columns = $table_schema->get_columns();

=cut

sub get_columns
{
	my ( $self ) = @_;

	if ( !defined( $self->{'columns'} ) )
	{
		my $table = $self->get_table();
		$self->{'columns'} = [ $table->columns() ];
	}

	return $self->{'columns'};
}


=head1 BUGS

Please report any bugs or feature requests through the web interface at
L<https://github.com/guillaumeaubert/DBIx-NinjaORM/issues/new>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc DBIx::NinjaORM::Schema::Table


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
