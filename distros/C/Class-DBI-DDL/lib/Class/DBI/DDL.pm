package Class::DBI::DDL;

use 5.008;
use strict;
use warnings;

our $VERSION = '1.02';

use base qw(Class::Data::Inheritable Class::DBI);

=head1 NAME

Class::DBI::DDL - Combined with Class::DBI to create and dispose of tables

=head1 SYNOPSIS

  package My::DBI;
  use base 'Class::DBI::DDL';

  # __PACKAGE__->set_db('Main', 'dbi:Pg:dbname=test', 'test', 'test');
  __PACKAGE->set_db('Main', 'dbi:mysql:test', 'test', 'test');

  package My::Folk;

  use base 'My::DBI';

  # Regular Class::DBI definitions...
  __PACKAGE__->table('folks');
  __PACKAGE__->columns(Primary => 'id');
  __PACKAGE__->columns(Essential => qw(first_name last_name age));
  __PACKAGE__->has_many(favorite_colors => 'My::Favorite');

  # DDL methods
  __PACKAGE__->column_definitions([
      [ id         => 'int',  'not null', 'auto_increment' ],
      [ first_name => 'varchar(20)', 'not null' ],
      [ last_name  => 'varchar(20)', 'not null' ],
      [ age        => 'numeric(3)',  'not null' ],
  ]);

  __PACKAGE__->index_definitions([
      [ Unique => qw(last_name first_name) ],
  ]);

  __PACKAGE__->create_table;

  package My::Favorite;

  use base 'My::DBI';

  # Class::DBI definitions...
  __PACKAGE__->table('favorites');
  __PACKAGE__->columns(Primary => 'id');
  __PACKAGE__->columns(Essential => qw(folk color));
  __PACKAGE__->has_a(folk => 'My::Folk');

  # DDL methods
  __PACKAGE__->column_definitions([
      [ id    => 'int',  'not null', 'auto_increment' ],
      [ folk  => 'numeric(5)',  'not null' ],
      [ color => 'varchar(20)', 'not null' ],
  ]);

  __PACKAGE__->index_definitions([
      [ Unique  => qw(folk color) ],
      [ Foreign => 'folk', 'My::Folk', 'id' ],
  ]);

  __PACKAGE__->create_table;

=head1 DESCRIPTION

This module is used to added to a L<Class::DBI> class to allow it to
automatically generate DDL calls to create a table if it doesn't exist in the
database already. It attempts to do so in such a way as to be database
independent whenever possible.

Use the typical C<Class::DBI> methods to build your class methods. Then, use
the C<column_definitions> and C<index_definitions> methods to define the
structure of the table. Finally, call C<create_table> and the system will
attempt to create the table if the table cannot be found.

=head2 DBI DEPENDENCE

The functionality provided by this library attempts to depend on as little that
is database or driver specific as possible. However, it does, at this time,
require that the DBD driver have a functioning C<tables> method for listing
tables in the database. Such dependence may later be emulated in the same way
L</DRIVER DEPENDENT OPERATIONS> is done, if necessary, but it is not at this
time.

=head2 DRIVER DEPENDENT OPERATIONS

It also has some special support for situations where standard SQL generation
will fail for a given database. The primary use of this facility is to make
sure that auto-increment fields are properly handled. This system uses the the
"auto_increment" property notation used by MySQL to handle this. This system
does not work well with the C<sequence> method of C<Class::DBI>.

=head2 METHODS

In addition to the method found in L<Class::DBI>, this package defines the
following:

=over

=item column_definitions

  __PACKAGE__->column_definitions($array_reference);

The array reference passed should contain an element for each column given to
the C<columns> method of C<Class::DBI>. Each element is an array reference
whose first element is the column name. The rest of the elements after the
column name are used to define the column. Typically, the column type will
be next followed by any flags, such as "NULL", "NOT NULL", "AUTO_INCREMENT",
etc. Don't use index constraints here such as "PRIMARY" or "UNIQUE".

=item index_definitions

  __PACKAGE__->index_definitions($array_reference);

The array reference passed should contain an element for each column index
to create in addition to the primary key. Currently, two index types are
supported: "UNIQUE" and "FOREIGN".  The "UNIQUE" index will create an index
that constrains the columns so that there are no duplicates in the given
fields. The "FOREIGN" index will create a link between databases and should
enforce referential integrity--if the underlying driver supports it.

Each element of the column index is an array reference whose first element
is the name of the type of index to use--this name is case-insensitive.
Following this are the arguments to that type of index, whose format varies
depending upon the index type:

=over

=item UNIQUE

For a "UNIQUE" index, an array or array reference contain column names
follows the "UNIQUE" keyword. The given column names will be used to create
the index.

=item FOREIGN

A "FOREIGN" index takes exactly three arguments. The first and third arguments
are column names and the second is the name of a package. The column name
arguments may either be a single column name, or an array reference containing
multiple column names. In any case, the first and third arguments must have
exactly the same number of elements. The package name in the second argument
should point to another C<Class::DBI> class that has already been defined.

=back

=cut

__PACKAGE__->mk_classdata('column_definitions');
__PACKAGE__->mk_classdata('index_definitions');
__PACKAGE__->mk_classdata('__ddl_helper');
__PACKAGE__->column_definitions([]);
__PACKAGE__->index_definitions([]);

# =item _list_tables
# 
#   @tables = __PACKAGE__->_list_tables
# 
# This method is not intended for external use, but is used to list all the
# tables the database driver is aware of. This is used in testing whether or not
# the actual CREATE or DROP expressions should be run--that is, since CREATE
# TABLE IF NOT EXISTS and DROP TABLE IF EXISTS are not available everywhere.
# 
# =cut
sub _list_tables {
	my $class = shift;
	my $dbh = $class->db_Main;
	return map { s/.*\.//; s/^(?:`|")//; s/(?:`|")//; $_ } $dbh->tables();
}

# =item _load_driver_specifics
#
#   $class->_load_driver_specifics;
#
# This method loads the helper class associated with the current driver. If no
# such class exists, then it will use the fall-back helpers (defined within this
# package). After this method is called the C<__ddl_helper> class accessor will
# contain the name of the package to be used for calling C<pre_create_table>,
# C<post_create_table>, C<pre_drop_table>, and C<post_drop_table>.
#
# =cut
sub _load_driver_specifics {
	my $class = shift;

	# Find the driver name
	my $driver_name = $class->db_Main->{Driver}->{Name};
	
	# Try to load the Class::DBI::DDL::$driver_name module
	eval qq(package Class::DBI::DDL::_safe; require Class::DBI::DDL::$driver_name);

	unless ($@) {
		# We've loaded Class::DBI::DDL::$driver_name
		$class->__ddl_helper("Class::DBI::DDL::$driver_name");
	} else {
		# An error occurred, we'll fall back to the defaults
		$class->__ddl_helper('Class::DBI::DDL');
	}
}

=item create_table

  __PACKAGE__->create_table;

  # -- OR --

  __PACKAGE__->create_table(sub { ... });

This method does most of the real work of this package. It takes the given
C<column_definitions> and C<index_definitions> and some other C<Class::DBI>
information to create the table if the table does not already exist in the
database.

If the method is passed a code reference, then the given code will be executed
if the table is created. The code reference will be called after the table
exists. This is so the user may populate the table with a "starter database"
if the table needs to have some data in it at creation time.

=cut

__PACKAGE__->set_sql(create_table => q(CREATE TABLE __TABLE__ (%s)));
__PACKAGE__->set_sql(drop_table   => q(DROP TABLE __TABLE__));

sub create_table {
	my $class = shift;
	my $on_create = shift;

	my $dbh = $class->db_Main;
	my $table = $class->table;
	my @tables = $class->_list_tables;

	if (!grep /^$table$/, @tables) {

		$class->_load_driver_specifics;
		$class->__ddl_helper->pre_create_table($class);

		my @decls;
		for my $column (@{ $class->column_definitions }) {
			push @decls, join(' ', @$column);
		}

		my @primary = $class->primary_columns;
		push @decls, sprintf('PRIMARY KEY (%s)', join(',', @primary));

		for my $index (@{ $class->index_definitions }) {
			my $type = $$index[0];
			if ($type =~ /unique/i) {
				if (ref $$index[1]) {
					push @decls, sprintf('UNIQUE (%s)', join(',', @{$$index[1]}));
				} else {
					push @decls, sprintf('UNIQUE (%s)', join(',', @$index[1 .. $#$index]));
				}
			} elsif ($type =~ /foreign/i) {
				my @from  = ref $$index[1] ? @{$$index[1]} : ($$index[1]);
				my $table = $$index[2];
				my @to    = ref $$index[3] ? @{$$index[3]} : ($$index[3]);

				push @decls, sprintf('FOREIGN KEY (%s) REFERENCES %s (%s)',
					join(',', @from), $table->table, join(',', @to));
			} else {
				Class::DBI::_croak "Unknown index type $type.";
			}
		}

		$class->sql_create_table(join(', ', @decls))->execute;
		$class->__ddl_helper->post_create_table($class);

		if (defined $on_create and ref $on_create eq 'CODE') {
			&$on_create;
		}
	}
}

=item drop_table

  __PACKAGE->drop_table;

This method undoes the work of C<create_table>. It does nothing if the table
doesn't exist.

=cut

sub drop_table {
	my $class = shift;

	my $dbh = $class->db_Main;
	my $table = $class->table;
	my @tables = $class->_list_tables;

	if (grep /^$table$/, @tables) {
		$class->_load_driver_specifics;
		$class->__ddl_helper->pre_drop_table($class);
		$class->sql_drop_table->execute;
		$class->__ddl_helper->post_drop_table($class);
	}
}

=back

=head2 HELPER METHODS

The C<Class::DBI::DDL> package uses helper methods named C<pre_create_table>,
C<post_create_table>, C<pre_drop_table>, and C<post_drop_table> to take care of
work that is specific to a database driver--specifically setting up 
auto_increment columns or stripping out unsupported constraints or indexes.

As of this writing, C<Class::DBI::DDL> supports C<DBD::Pg> and C<DBD::mysql>
directly, but provides a default that is general enough to work under most
other environments. To define a new helper for another database driver, just
create a package named C<Class::DBI::DDL::Driver>, where C<Driver> is the name
of the database driver name returned by:

  $dbh->{Driver}->{Name}

After this class is installed somewhere in the Perl include path, it will be
automatically loaded. If you create such a driver, please send it to me and I
will consider its inclusion in the next release.

Here are described the workings of the default helper methods--please let me
know if this could be improved to be more general as this is largely untested!

=over

=item pre_create_table

  Class::DBI::DDL::Driver->pre_create_table($class)

As its first argument (besides the invocant) it is passed the class name of the
caller. This method is called before C<create_table> processes any of the column
or index information. 

The default method simply checks for the C<auto_increment> property in the
column definitions. If found, it drops the C<auto_increment> property and adds a
trigger that finds the maximum value in the column and adds one to that value
and sets the column to the incremented value. Thus, this emulates the
auto_increment feature for any database that supports the MAX aggregate
function.

=cut

__PACKAGE__->set_sql(select_auto_increment => q(
	SELECT MAX(%s)+1 FROM __TABLE__
));

sub pre_create_table {
	my ($class, $self) = @_;

	# For each column with an auto_increment property, drop that property and
	# add triggers to set those values on insert to MAX($column)+1.
	for my $column (@{$self->column_definitions}) {
		if (grep /^auto_increment$/i, @{$column}[1 .. $#$column]) {
			$self->add_trigger(before_create => sub { 
				my $self = shift;
				my $sth = $self->sql_select_auto_increment($$column[0]);
				$sth->execute;
				my @row = $sth->fetchall;
				$self->{$$column[0]} = $row[0][0] || 1;
			});
			@$column = grep !/^auto_increment$/i, @$column;
		}
	}
}

=item post_create_table

  Class::DBI::DDL::Driver->post_create_table($class)

As its argument (besides the invocant) it is passed the class name of the
caller. This method is called after C<create_table> has created the table and
before the start database method is called (if present).

The default method does nothing.

=cut

sub post_create_table { }

=item pre_drop_table

  Class::DBI::DDL::Driver->pre_drop_table($class)

As its argument (besides the invocant) it is passed the class name of the
caller. This method is called before C<drop_table> drops the table.

The default method does nothing.

=cut

sub pre_drop_table { }

=item post_drop_table

  Class::DBI::DDL::Driver->post_drop_table($class)

As its argument (besides the invocant) it is passed the class name of the
caller. This method is called after C<drop_table> drops the table.

The default method does nothing.

=cut

sub post_drop_table { }

=back

=head1 SEE ALSO

L<Class::DBI>, L<DBI>

=head1 AUTHOR

Andrew Sterling Hanenkamp <sterling@hanenkamp.com>

=head1 LICENSE AND COPYRIGHT

Copyright 2003 Andrew Sterling Hanenkamp. All Rights Reserved.

This module is free software and is distributed under the same license as Perl
itself.

=cut

1
