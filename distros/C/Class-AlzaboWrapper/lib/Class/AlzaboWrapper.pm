package Class::AlzaboWrapper;

use strict;

use vars qw($VERSION);

$VERSION = '0.14';

use Class::AlzaboWrapper::Cursor;

use Exception::Class ( qw( Class::AlzaboWrapper::Exception Class::AlzaboWrapper::Exception::Params ) );
Class::AlzaboWrapper::Exception->Trace(1);
Class::AlzaboWrapper::Exception::Params->Trace(1);

use Params::Validate qw( validate validate_pos validate_with SCALAR UNDEF ARRAYREF HASHREF );
Params::Validate::validation_options
    ( on_fail =>
      sub { Class::AlzaboWrapper::Exception::Params->throw
                ( message => join '', @_ ) } );

my %TableToClass;
my %ClassToTable;
my %ClassAttributes;

BEGIN
{
    foreach my $meth ( qw( select update delete is_live ) )
    {
        my $sub = sub { shift->row_object->$meth(@_) };

        no strict 'refs';
        *{ __PACKAGE__ . "::$meth" } = $sub;
    }
}

sub import
{
    my $class = shift;

    # called via 'use base'
    return unless @_;

    my %p =
        validate_with( params => \@_,
                       spec   =>
                       { caller => { type    => SCALAR,
                                     default => (caller(0))[0] },
                         base   => { type    => SCALAR,
                                     default => __PACKAGE__ },
                       },
                       allow_extra => 1,
                     );

    my $base = delete $p{base};
    eval "package $p{caller}; use base '$base'";

    $class->_make_methods(%p);
}

sub _make_methods
{
    my $class = shift;

    my %p = validate( @_,
                      { skip   => { type => SCALAR | ARRAYREF, default => [] },
                        table  => { isa => 'Alzabo::Table' },
                        caller => { type => SCALAR, default => $class },
                      }
                    );

    my $caller = delete $p{caller};

    $caller->SetAlzaboTable( delete $p{table} );
    $caller->MakeColumnMethods(%p);
}

sub SetAlzaboTable
{
    my $class = shift;
    my ($table) = validate_pos( @_, { isa => 'Alzabo::Table' } );

    $TableToClass{ $table->name } = $class;
    $ClassToTable{$class} = $table;
}

sub Table
{
    my $class = ref $_[0] || $_[0];

    Class::AlzaboWrapper::Exception->throw
        ( error => "Must call SetTable() before calling Table() on $class" )
            unless $ClassToTable{$class};

    return $ClassToTable{$class};

}
# deprecated
*table = \&Table;

sub MakeColumnMethods
{
    my $class = shift;
    my %p = validate( @_,
                      { skip   => { type => SCALAR | ARRAYREF, default => [] },
                      }
                    );

    my %skip = map { $_ => 1 } ref $p{skip} ? @{ $p{skip} } : $p{skip};

    my $table = $class->Table;
    foreach my $name ( map { $_->name } $table->columns )
    {
        next if $skip{$name};

        $class->_RecordAttributeCreation( $class => $name );

        my $cache_key = '__cache__' . $name;

        my $sub = sub { my $self = shift;

                        return $self->{$cache_key}
                            if exists $self->{$cache_key};

                        $self->{$cache_key} = $self->row_object->select($name);
                      };

        no strict 'refs';
        *{"$class\::$name"} = $sub;
    }
}

sub _RecordAttributeCreation { push @{ $ClassAttributes{ $_[1] } }, $_[2] }
# deprecated
*_record_attribute_creation = \&_RecordAttributeCreation;

sub new
{
    my $class = shift;

    my @pk = $class->table->primary_key;

    my @pk_spec =
        map { $_->name => { type => SCALAR | UNDEF, optional => 1 } } @pk;

    my %p =
        validate_with( params => \@_,
                       spec =>
                       { object =>
                         { isa => 'Alzabo::Runtime::Row', optional => 1 },
                         @pk_spec,
                       },
                       allow_extra => 1,
                     );

    my %pk;
    foreach my $col (@pk)
    {
        if ( exists $p{ $col->name } )
        {
            $pk{ $col->name } = $p{ $col->name };
        }
    }

    my $row;
    if ( keys %pk == @pk )
    {
        $row = eval { $class->table->row_by_pk( pk => \%pk ) };
    }
    elsif ( exists $p{object} )
    {
        $row = $p{object};
    }
    else
    {
        $row = $class->_new_row(%p) if $class->can('_new_row');
    }

    return unless $row;

    my $self = bless { row => $row }, $class;

    $self->_init(%p) if $self->can('_init');

    return $self;
}

sub create
{
    my $class = shift;
    my %p = @_;

    my %values;

    for my $c ( map { $_->name } $class->table->columns )
    {
        $values{$c} = delete $p{$c} if exists $p{$c};
    }

    my $row =
        $class->table->insert
            ( values => \%values );

    return $class->new( object => $row, %p );
}

sub potential
{
    my $class = shift;

    return
        $class->new( object => $class->table->potential_row( values => {@_} ) );
}

sub Columns { shift->table->columns(@_) }
*Column = \&Columns;
# deprecated
*columns = \&Columns;
*column = \&Columns;

sub NewCursor
{
    my $self = shift;
    my $cursor = shift;

    return
        Class::AlzaboWrapper::Cursor->new
            ( cursor => $cursor );
}
# deprecated
*cursor = \&NewCursor;


sub TableToClass { $TableToClass{ $_[1]->name } }
# deprecated
*table_to_class = \&TableToClass;

sub AlzaboAttributes
{
    my $class = ref $_[0] || $_[0];

    @{ $ClassAttributes{$class} };
}
# deprecated
*alzabo_attributes = \&AlzaboAttributes;

sub row_object { $_[0]->{row} }


1;

__END__

=head1 NAME

Class::AlzaboWrapper - Higher level wrapper around Alzabo Row and Table objects

=head1 SYNOPSIS

  package WebTalk::User;
  use base 'Class::AlzaboWrapper';

  __PACKAGE->SetAlzaboTable( $schema->table('User') );
  __PACKAGE->MakeColumnMethods();

=head1 DESCRIPTION

This module is intended for use as a base class when you are writing
a class that wraps Alzabo's table and row classes.

It also provides a way to generate some methods specific to your
subclass.

=head1 USAGE

Our usage examples will assume that there is database containing
tables named "User" and "UserComment", and that the subclass we are
creating is called C<WebTalk::User>.

=head2 Exceptions

This module throws exceptions when invalid parameters are given to
methods.  The exceptions it throws are objects which inherit from
C<Exception::Class::Base>, just as with Alzabo itself.

=head2 SetAlzaboTable()

This method must be called by your subclass or almost none of the
methods provided by C<Class::AlzaboWrapper> will work.

=head2 Inherited methods

Subclasses inherit a number of method from C<Class::AlzaboWrapper>.

=head3 Class methods

=over 4

=item * new(...)

The C<new()> method provided allows you to create new objects either
from an Alzabo row object, or from the main table's primary keys.

This method first looks to see if the parameters it was given match
the table's primary key.  If they do, it attempts to create an object
using those parameters.  If no primary key values are given, then it
looks for an parameter called "object", which should be an
C<Alzabo::Runtime::Row> object.

Finally, if your subclass defines a C<_new_row()> method, then this
will be called, with all the parameters provided to the C<new()>
method.  This allows you to create new objects based on other
parameters.

If your subclass defines an C<_init()> method, then this will be
called after the object is created, before it is returned from the
C<new()> method to the caller.

If invalid parameters are given then this method will throw a
C<Class::AlzaboWrapper::Exception::Params> exception.

=item * create(...)

This method is used to create a new object and insert it into the
database.  It simply calls the C<insert()> method on the class's
associated table object.  Any parameters given to this method are
passed given to the C<insert()> method as its "values" parameter.

=item * potential(...)

This creates a new object based on a potential row, as opposed to one
in the database.  Similar to the C<create()> method, any parameters
passed are given to the table's C<potential_row()> method as the
"values" parameter.

=item * Columns(...)

This is simply a shortcut to the associated table's C<columns> method.
This may also be called as an object method.

=item * Column(...)

This is simply a shortcut to the associated table's C<column> method.
This may also be called as an object method.

=item * Table()

This method returns the Alzabo table object associated with the
subclass.  This may also be called as an object method.

=item * AlzaboAttributes()

Returns a list of accessor methods that were created based on the
columns in the class's associated table.

=item * NewCursor ($cursor)

Given an C<Alzabo::Runtime::Cursor> object (either a row or join
cursor), this method returns a new C<Class::AlzaboWrapper::Cursor>
object.

=back

=head3 Object methods

=over 4

=item * row_object()

This method returns the C<Alzabo::Runtime::Row> object associated with
the given subclass object.  So, for our hypothetical C<WebTalk::User>
class, this would return an object representing the underlying row
from the User table.

=item * select() / update() / delete() / is_live()

These methods are simply passthroughs to the underlying Alzabo row
methods of the same names.  You may want to subclass some of these in
order to change their behavior.

=back

=head3 MakeColumnMethods(...)

If you call this method on your subclass, then for each column in the
associated table, a method will be created in your subclass that
selects that column's value from the underlying row for an object.

For example, if our User table contained "username" and "email"
columns, then our C<WebTalk::User> object would have C<username()> and
C<email()> methods generated.

The C<MakeColumnMethods()> method accepts a "skip" parameter which can
be either a scalar or array reference.  This is a list of columns for
which methods I<should not> be generated.

=head3 Class::AlzaboWrapper methods

The C<Class::AlzaboWrapper> module has a method it provides:

=over 4

=item * TableToClass($table)

Given an Alzabo table object, this method returns its associated
subclass.

=back

=head3 Cursors

When using this module, you need to use the
C<Class::AlzaboWrapper::Cursor> module to wrap Alzabo's cursor
objects, so that objects the cursor returns are of the appropriate
subclass, not plain C<Alzabo::Runtime::Row> objects.  The C<Cursor()>
method provides some syntactic sugar for creating
C<Class::AlzaboWrapper::Cursor> objects.

=head3 Attributes created by subclasses

If you want to record the accessor methods your subclass makes so they
are available via C<AlzaboAttributes()>, you can call the
C<_RecordAttributeCreation()> method, which expects two arguments.
The first argument is the class for which the method was created and
the second is the name of the method.

=head1 SUPPORT

The Alzabo docs are conveniently located online at
http://www.alzabo.org/docs/.

There is also a mailing list.  You can sign up at
http://lists.sourceforge.net/lists/listinfo/alzabo-general.

Please don't email me directly.  Use the list instead so others can
see your questions.

=head1 SEE ALSO

VegGuide.Org is a site I created which actually uses this code as part
of the application.  Its source is available from the web site.

=head1 COPYRIGHT

Copyright (c) 2002-2005 David Rolsky.  All rights reserved.  This
program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included
with this module.

=head1 AUTHOR

Dave Rolsky, <autarch@urth.org>

=cut
