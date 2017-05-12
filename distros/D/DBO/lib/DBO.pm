#------------------------------------------------------------------------------
# DBO - Database Objects
#
# DESCRIPTION
#   An object-oriented database abstraction layer.
#
# AUTHOR
#   Gareth Rees
#
# COPYRIGHT
#   Copyright (c) 1999 Canon Research Centre Europe Ltd/
#
# $Id: DBO.pm,v 1.4 1999/06/29 17:09:30 garethr Exp $
#------------------------------------------------------------------------------

use strict;
package DBO;
use base 'Exporter';
use Carp;
use UNIVERSAL 'isa';
use Class::Multimethods qw(visit_database visit_table);
use vars qw($VERSION $DEBUG @EXPORT_OK %EXPORT_TAGS);

$VERSION = '0.01';
$DEBUG = 0;
@EXPORT_OK = qw(Database Table Key Option ForeignKey Char Text Integer Unsigned AutoIncrement Time);
%EXPORT_TAGS = (constructors => [qw(Database Table Key Option ForeignKey Char Text Integer Unsigned AutoIncrement Time)]);

sub new {
  my $class = shift;
  my $self = bless { @_ }, $class;

  # Check that the schema argument is a DBO::Database.
  isa($self->{schema},'DBO::Database')
    or croak(DBO::Exception->new
	     (SCHEMA => "'schema' must be a DBO::Database, not %s.",
	      ref $self->{schema}));

  # Check that the handle argument is a DBO::Handle.
  isa($self->{handle},'DBO::Handle')
    or croak(DBO::Exception->new
	     (HANDLE => "'handle' must be a DBO::Handle, not %s.",
	      ref $self->{handle}));

  # Apply the Initialize visitor.
  require DBO::Visitor::Initialize;
  $self->apply_to_database('DBO::Visitor::Initialize');

  return $self;
}

sub DESTROY {
  my $self = shift;
  $self->{dbh}->disconnect;
}

sub apply_to_database {
  my $self = shift;
  my $vis = shift;
  $vis = $vis->new(@_) unless ref $vis;
  visit_database($vis, $self->{schema}, $self->{handle});
}

sub apply_to_table {
  my $self = shift;
  my $id = shift;
  my $table = $self->{schema}->lookup_table($id)
    or die DBO::Exception->new(NO_SUCH_TABLE => "No such table: %s", $id);
  my $vis = shift;
  $vis = $vis->new(@_) unless ref $vis;
  visit_table($vis, $table, $self->{handle});
}

sub error {
  my $self = shift;
  $self->{error} = shift;
}

#------------------------------------------------------------------------------
# Constructor functions (for convenience)
#------------------------------------------------------------------------------

sub Database       { DBO::Database->new(@_) }
sub Table          { DBO::Table->new(@_) }
sub Key		   { DBO::Column::Key->new(@_) }
sub Option	   { DBO::Column::Option->new(@_) }
sub ForeignKey	   { DBO::Column::ForeignKey->new(@_) }
sub Char	   { DBO::Column::Char->new(@_) }
sub Text	   { DBO::Column::Text->new(@_) }
sub Integer	   { DBO::Column::Integer->new(@_) }
sub Unsigned	   { DBO::Column::Unsigned->new(@_) }
sub AutoIncrement  { DBO::Column::AutoIncrement->new(@_) }
sub Time	   { DBO::Column::Time->new(@_) }


#------------------------------------------------------------------------------
# DBO::Handle - handle to a database
#------------------------------------------------------------------------------

package DBO::Handle;

package DBO::Handle::DBI;
use base 'DBO::Handle';
use vars '$AUTOLOAD';

sub connect {
  my $class = shift;
  require DBI;
  my $dbh = DBI->connect(@_) or return;
  bless \$dbh, $class;
}

sub dosql {
  my $self = shift;
  my $sql = join ' ', @_;
  $$self->do($sql)
    or croak(DBO::Exception->new
	     (SQL => "Failed to execute SQL statement %s: %s.",
	      $sql, $$self->errstr));
}

sub AUTOLOAD {
  my $self = shift;
  my $method = $AUTOLOAD;
  $method =~ s/.*://;
  $$self->$method(@_);
}

package DBO::Handle::DBI::mSQL;
use base 'DBO::Handle::DBI';

package DBO::Handle::DBI::mysql;
use base 'DBO::Handle::DBI';


#------------------------------------------------------------------------------
# DBO::Exception - class of exceptions
#------------------------------------------------------------------------------

package DBO::Exception;

sub new {
  my $class = shift;
  my $exception = shift;
  my $default = shift;
  my $self = bless { exception => $exception,
		     default => $default,
		     args => [ @_ ] }, $class;
  warn $self->format if $DBO::DEBUG;
  return $self;
}

sub format {
  my $self = shift;
  sprintf $self->{default}, @{$self->{args}};
}


#------------------------------------------------------------------------------
# DBO::Database - abstract representation of a database
#------------------------------------------------------------------------------

package DBO::Database;
use Class::Multimethods 'visit_database';

sub new {
  my $class = shift;
  my $self = bless { @_ }, $class;
  return $self;
}

sub lookup_table {
  my $self = shift;
  my $id = shift;
  $self->{tables_by_id}{$id};
}


#------------------------------------------------------------------------------
# DBO::Table - abstract representation of a database table
#------------------------------------------------------------------------------

package DBO::Table;
use Class::Multimethods 'visit_table';

sub new {
  my $class = shift;
  my $self = bless { @_ }, $class;
  return $self;
}

sub lookup_column {
  my $self = shift;
  my $id = shift;
  $self->{columns_by_id}{$id};
}


#------------------------------------------------------------------------------
# DBO::Column - abstract representation of a database column
#------------------------------------------------------------------------------

package DBO::Column;
use Class::Multimethods 'visit_column';

sub new {
  my $class = shift;
  my $self = bless { @_ }, $class;
  return $self;
}

sub visit {
  my $self = shift;
  my $visitor = shift;
  visit_column($visitor, $self);
}

package DBO::Column::Modifier;
use base 'DBO::Column';

package DBO::Column::Key;
use base 'DBO::Column::Modifier';

package DBO::Column::Option;
use base 'DBO::Column::Modifier';

package DBO::Column::ForeignKey;
use base 'DBO::Column::Modifier';

package DBO::Column::Base;
use base 'DBO::Column';

package DBO::Column::Number;
use base 'DBO::Column::Base';

package DBO::Column::String;
use base 'DBO::Column::Base';

package DBO::Column::Char;
use base 'DBO::Column::String';

package DBO::Column::Text;
use base 'DBO::Column::String';

package DBO::Column::Integer;
use base 'DBO::Column::Number';

package DBO::Column::Unsigned;
use base 'DBO::Column::Integer';

package DBO::Column::AutoIncrement;
use base 'DBO::Column::Unsigned';

package DBO::Column::Time;
use base 'DBO::Column::Char';


#------------------------------------------------------------------------------
# DBO::Visitor - an action on a database
#------------------------------------------------------------------------------

package DBO::Visitor;
use Class::Multimethods;

sub new {
  my $class = shift;
  my $self = bless { @_ }, $class;
  return $self;
}

multimethod visit_database =>
  qw(DBO::Visitor DBO::Database DBO::Handle) =>
sub {
  my ($vis, $database, $handle) = @_;
  foreach my $table (@{$database->{tables}}) {
    visit_table($vis, $table, $handle);
  }
};

multimethod visit_table =>
  qw(DBO::Visitor DBO::Table DBO::Handle) =>
sub {
  my ($vis, $table, $handle) = @_;
  foreach my $col (@{$table->{columns}}) {
    visit_column($vis, $col, $handle);
  }
};

multimethod visit_column =>
  qw(DBO::Visitor DBO::Column::Base DBO::Handle) =>
sub {
  # my ($vis, $col, $handle) = @_;
};

multimethod visit_column =>
  qw(DBO::Visitor DBO::Column::Modifier DBO::Handle) =>
sub {
  my ($vis, $col, $handle) = @_;
  visit_column($vis, $col->{base}, $handle);
};

1;

__END__


=head1 NAME

C<DBO> - Database Objects


=head1 SYNOPSIS

  use DBO ':constructors';

  $dbh = DBO::Handle::DBI::mysql->connect
    ('dbi:mysql:database:host', 'larry', 'camel');

  $schema = Database
    ( tables =>
      [ Table
	( name => 'person',
	  columns =>
	  [ Char(name => 'name', max_length => 100 ),
	    Text(name => 'address'),
            Char(name => 'phone', max_length => 30 )])]);

  $dbo = DBO->new
  ( handle => $dbh,
    schema => $schema );

  use DBO::Visitor::Create;
  $dbo->apply_to_database('DBO::Visitor::Create');


=head1 DESCRIPTION

C<DBO> is an object-oriented database abstraction layer.

C<DBO> is designed to be flexibly extensible in a number of directions -
adding new operations on the database, adding new kinds of tables or
columns, and applying to new database systems.  All extensions can be
carried out by creating new classes that inherit from the classes C<DBO>
defines, and by defining new multimethod instances for those classes.

C<DBO> defines three class hierarchies:

=over 4

=item Database operations

An operation on a database is represented by an object belonging to the
class C<DBO::Visitor>.  C<DBO> provides a number of operations including
C<Create>, C<Insert> and C<Select>.

=item Schema elements

The structure of the database is represented by an object belonging to
the class C<DBO::Database>, which contains a number of tables
represented by C<DBO::Table>, each of which contains a number of columns
represented by C<DBO::Column>.  C<DBO> defines many column types,
including C<Char>, C<Text>, C<Unsigned>, C<Integer> and C<Time>.

Additional features of columns in the schema - such as the values in the
column being restricted to a set of options, or the column being one of
the keys of the table - are represented by wrapping the column with a
C<Modifier> class.  C<DBO> defines the modifier classes C<Key>,
C<Option> and C<ForeignKey>.  Each column object belonging to the
modifier class has a reference to another column object that describes
the underlying type of the column.

(This design allows a C<ForeignKey> column to be implemented by a
C<Char> or C<Integer> or whatever, as the designer wishes, without
needing extra classes C<ForeignKey_Char>, C<ForeignKey_Integer> and so
on.)

=item Database handles

The database itself is represented by an object belong to the class
C<DBO::Handle>.  C<DBO> defines the class C<DBO::Handle::DBI> as a thin
wrapper around C<DBI>, but the facility is there for C<DBO> to be
applied to other kinds of database (or to define more sophisticated
wrappers around C<DBI> such as "virtual databases" - views that include
data from more than one database).

=back

The application of an operation to an element of the schema is
represented by a multimethod instance.  DBO uses three multimethods:

=over

=item visit_database($visitor, $database, $handle)

=item visit_table($visitor, $table, $handle)

=item visit_column($visitor, $column, $handle)

=back

When $visitor is the generic visitor C<DBO::Visitor>, C<visit_database>
visits all the tables in the database; C<visit_table> visits all the
columns in the table, C<visit_column> visits the base column when
$column is a C<Modifier> column, and does nothing otherwise.

See L<Class::Multimethods> for the full details of the multimethod
implementation.


=head1 PACKAGE OPTION

By default, the C<DBO> package exports no names and expects you to use a
purely object-oriented interface.

However, a number of constructor functions simplify the building of
schemas, and these can be imported by passing the C<:constructors> key
to the C<use DBO> statement.  Then you can write

    Text(name => 'address')

as a shorthand for

    DBO::Column::Text->new(name => 'address')


=head1 THE DBO OBJECT

The C<DBO> class packages up the database schema and the database handle
into one object, with a couple of convenience functions for creating and
applying operations.  (You don't need to use a C<DBO> object if you
don't want to.)

C<DBO-E<gt>new> takes a list of keys and values.  The following keys are
required:

=over

=item C<schema>

A database schema, represented by an object of class C<DBO::Database>.

=item C<handle>

A database handle, represented by an object of class C<DBO::Handle>.

=back


=head1 SCHEMA ELEMENTS

All constructors for schema elements are called C<new>, and take a list
of keys and values.

=head2 C<DBO::Database>

A database.  The following key is defined:

=over

=item C<tables>

A reference to an array of the tables in the database (each represented
by a C<DBO::Table> object).  Required.

=back

=head2 C<DBO::Table>

A table; or more specifically a view onto a table (you can have many
views onto the same table).  The following keys are defined:

=over

=item C<id>

An identifying name for this object.  The tables belonging to a
particular database must have different C<id>s (this only matters when
there is more than one view onto the same table).  If not supplied, the
value for the C<name> key is used instead.

=item C<name>

The name of the table in the database.  Required.

=item C<columns>

A reference to an array of the columns in the table (each represented
by a C<DBO::Column> object).  Required.

=back

=head2 C<DBO::Column>

A generic column.

=head2 C<DBO::Column::Base>

A column implementation in a table in the database.  The following keys
are defined:

=over

=item C<name>

The name of the column in the table.  Required.

=item C<not_null>

True iff entries in the column are allowed to be NULL.

=back

=head2 C<DBO::Column::Number>

A column whose values are numbers.

=head2 C<DBO::Column::Integer>

A column whose values are integers.

=head2 C<DBO::Column::Unsigned>

A column whose values are non-negative integers.

=head2 C<DBO::Column::String>

A column whose values are strings.

=head2 C<DBO::Column::Char>

A column whose values are fixed-length strings.  The following key is
defined:

=over

=item C<max_length>

The maximum length of a value for the column.  Defaults to 10.

=back

=head2 C<DBO::Column::Text>

A column whose values are variable-length strings.  The following keys
are defined:

=over

=item C<avg_length>

The average length of a value for the column.  Defaults to 100.  This is
a performance hint for some databases (e.g. mSQL) and ignored elsewhere.

=item C<max_length>

The maximum length of a value for the column.  Defaults to 1000.  For
databases that support arbitrarily long strings, this is ignored.

=back




=head1 RATIONALE



=head1 SEE ALSO

See L<Class::Multimethods> (Damian Conway) for the implementation of
multimethods in Perl.

See L<DBI> (Tim Bunce) for Perl's database independent interface.

"Design patterns: elements of reusable object-oriented software" by
Erich Gamma, Richard Helm, Ralph Johnson and John Vlissides
(Addison-Wesley 1995) describes the Visitor pattern.


=head1 AUTHOR

Gareth Rees C<garethr@cre.canon.co.uk>.


=head1 COPYRIGHT

Copyright (c) 1999 Canon Research Centre Europe Ltd.  All rights
reserved.


=cut

