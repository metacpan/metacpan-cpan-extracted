package Alzabo::RDBMSRules;

use strict;
use vars qw($VERSION);

use Alzabo::Exceptions ( abbr => [ 'recreate_table_exception' ] );

use Class::Factory::Util;
use Params::Validate qw( validate validate_pos );
Params::Validate::validation_options( on_fail => sub { Alzabo::Exception::Params->throw( error => join '', @_ ) } );

$VERSION = 2.0;

1;

sub new
{
    shift;
    my %p = @_;

    eval "use Alzabo::RDBMSRules::$p{rdbms};";
    Alzabo::Exception::Eval->throw( error => $@ ) if $@;
    return "Alzabo::RDBMSRules::$p{rdbms}"->new(@_);
}

sub available { __PACKAGE__->subclasses }

# validation

sub validate_schema_name
{
    shift()->_virtual;
}

sub validate_table_name
{
    shift()->_virtual;
}

sub validate_column_name
{
    shift()->_virtual;
}

sub validate_column_type
{
    shift()->_virtual;
}

sub validate_column_length
{
    shift()->_virtual;
}

sub validate_table_attribute
{
    shift()->_virtual;
}

sub validate_column_attribute
{
    shift()->_virtual;
}

sub validate_primary_key
{
    shift()->_virtual;
}

sub validate_sequenced_attribute
{
    shift()->_virtual;
}

sub validate_index
{
    shift()->_virtual;
}

sub type_is_numeric
{
    my $self = shift;
    my $col  = shift;

    return $self->type_is_integer($col) || $self->type_is_floating_point($col);
}

sub type_is_integer
{
    shift()->_virtual;
}

sub type_is_floating_point
{
    shift()->_virtual;
}

sub type_is_character
{
    shift()->_virtual;
}

sub type_is_date
{
    shift()->_virtual;
}

sub type_is_datetime
{
    shift()->_virtual;
}

sub type_is_time
{
    shift()->_virtual;
}

sub type_is_time_interval
{
    shift()->_virtual;
}

sub type_is_blob
{
    shift()->_virtual;
}

sub blob_type
{
    shift()->virtual;
}

# feature probing

sub column_types
{
    shift()->_virtual;
}

sub feature
{
    return 0;
}

sub quote_identifiers { 0 }

sub quote_identifiers_character { '' }

sub schema_attributes
{
    shift()->_virtual;
}

sub table_attributes
{
    shift()->_virtual;
}

sub column_attributes
{
    shift()->_virtual;
}

sub schema_sql
{
    my $self = shift;

    validate_pos( @_, { isa => 'Alzabo::Schema' } );

    my $schema = shift;

    my @sql;

    local $self->{state};

    foreach my $t ( $schema->tables )
    {
        push @sql, $self->table_sql($t);
    }

    return @sql, @{ $self->{state}{deferred_sql} || [] };
}

sub table_sql
{
    shift()->_virtual;
}

sub column_sql
{
    shift()->_virtual;
}

sub index_sql
{
    my $self = shift;
    my $index = shift;

    my $index_name = $index->id;
    $index_name = $self->quote_identifiers_character . $index_name . $self->quote_identifiers_character;

    my $sql = 'CREATE';
    $sql .= ' UNIQUE' if $index->unique;
    $sql .= " INDEX $index_name ON ";
    $sql .= $self->quote_identifiers_character;
    $sql .= $index->table->name;
    $sql .= $self->quote_identifiers_character;
    $sql .= ' ( ';

    if ( defined $index->function )
    {
        $sql .= $index->function;
    }
    else
    {
        $sql .=
            ( join ', ',
              map { $self->quote_identifiers_character . $_->name . $self->quote_identifiers_character }
              $index->columns
            );
    }

    $sql .= ' )';

    return $sql;
}

sub foreign_key_sql
{
    shift()->_virtual;
}

sub drop_table_sql
{
    my $self = shift;

    my $name = shift->name;
    $name = $self->quote_identifiers_character . $name . $self->quote_identifiers_character;

    return "DROP TABLE $name";
}

sub drop_column_sql
{
    shift()->_virtual;
}

sub drop_index_sql
{
    shift()->_virtual;
}

sub drop_foreign_key_sql
{
    shift()->_virtual;
}

sub column_sql_add
{
    shift()->_virtual;
}

sub column_sql_diff
{
    shift()->_virtual;
}

sub index_sql_diff
{
    my $self = shift;

    validate( @_, { new => { isa => 'Alzabo::Index' },
                    old => { isa => 'Alzabo::Index' } } );

    my %p = @_;

    my $new_sql = $self->index_sql($p{new});

    my @sql;
    if ( $new_sql ne $self->index_sql($p{old}) )
    {
        push @sql, $self->drop_index_sql( $p{old}, $p{new}->table->name );
        push @sql, $new_sql;
    }

    return @sql;
}

sub alter_primary_key_sql
{
    shift()->_virtual;
}

sub can_alter_table_name
{
    1;
}

sub can_alter_column_name
{
    1;
}

sub alter_table_name_sql
{
    shift()->_virtual;
}

sub alter_column_name_sql
{
    shift()->_virtual;
}

sub recreate_table_sql
{
    shift()->_virtual;
}

=pod

sub reverse_engineer
{
    my $self = shift;
    my $schema = shift;

    my $dbh = $schema->driver->handle;

    foreach my $table ( $dbh->tables )
    {
        my $t = $schema->make_table( name => $table );

        $self->reverse_engineer_table($t);
    }
}

sub reverse_engineer_table
{
    my $self = shift;
    my $table = shift;

    my $dbh = $table->schema->driver->handle;

    my $sth = $dbh->column_info( undef, $table->schema->name, $table->name, undef );

    while ( my $col_info = $sth->fetchrow_hashref )
    {
        use Data::Dumper; warn Dumper $col_info;
        my %attr = ( name     => $col_info->{COLUMN_NAME},
                     type     => $col_info->{TYPE_NAME},
                     nullable => $col_info->{NULLABLE} ? 1 : 0,
                   );

        $attr{size} =
            $col_info->{COLUMN_SIZE} if $col_info->{COLUMN_SIZE};

        $attr{precision} =
            $col_info->{DECIMAL_DIGITS} if $col_info->{DECIMAL_DIGITS};

        $attr{default} =
            $col_info->{COLUMN_DEF} if defined $col_info->{COLUMN_DEF};

        $attr{comment} =
            $col_info->{REMARKS} if defined $col_info->{REMARKS};

        $table->make_column(%attr);
    }

    $self->reverse_engineer_table_primary_key($table);
}

sub reverse_engineer_table_primary_key
{
    my $self = shift;
    my $table = shift;

    my $dbh = $table->schema->driver->handle;

    my $sth = $dbh->column_info( undef, $table->schema->name, $table->name );

    while ( my $pk_info = $sth->fetchrow_hashref )
    {
        $table->add_primary_key( $table->column( $pk_info->{COLUMN_NAME} ) );
    }
}

=cut

sub rules_id
{
    shift()->_virtual;
}

sub schema_sql_diff
{
    my $self = shift;

    validate( @_, { new => { isa => 'Alzabo::Schema' },
                    old => { isa => 'Alzabo::Schema' } } );

    my %p = @_;

    local $self->{state};

    my @sql;
    my %changed_name;
    foreach my $new_t ( $p{new}->tables )
    {
        # When syncing against an existing schema, the table may be
        # present with its new name.
        my $old_t;
        if ( defined $new_t->former_name )
        {
            $old_t = eval { $p{old}->table( $new_t->former_name ) };
        }

        $old_t ||= eval { $p{old}->table( $new_t->name ) };

        if ($old_t)
        {
            if ( $old_t->name ne $new_t->name )
            {
                $changed_name{ $old_t->name } = 1;

                if ( $self->can_alter_table_name )
                {
                    push @sql, $self->alter_table_name_sql($new_t);
                }
                else
                {
                    push @sql, $self->recreate_table_sql( new => $new_t,
                                                          old => $old_t,
                                                        );
                    push @sql, $self->rename_sequences( new => $new_t,
                                                        old => $old_t,
                                                      );

                    # no need to do more because table will be
                    # recreated from scratch
                    next;
                }
            }

            push @sql,
                eval { $self->table_sql_diff( new => $new_t,
                                              old => $old_t ) };

            if ( my $e = Exception::Class->caught('Alzabo::Exception::RDBMSRules::RecreateTable' ) )
            {
                push @sql, $self->recreate_table_sql( new => $new_t,
                                                      old => $old_t,
                                                    );
            }
            elsif ( $e = $@ )
            {
                die $e;
            }
        }
        else
        {
            push @sql, $self->table_sql($new_t);
            foreach my $fk ( $new_t->all_foreign_keys )
            {
                push @{ $self->{state}{deferred_sql} }, $self->foreign_key_sql($fk);
            }
        }
    }

    foreach my $old_t ( $p{old}->tables )
    {
        unless ( $changed_name{ $old_t->name } ||
                 eval { $p{new}->table( $old_t->name ) } )
        {
            push @sql, $self->drop_table_sql($old_t);
        }
    }

    return @sql, @{ $self->{state}{deferred_sql} || [] };
}

sub table_sql_diff
{
    my $self = shift;

    validate( @_, { new => { isa => 'Alzabo::Table' },
                    old => { isa => 'Alzabo::Table' } } );

    my %p = @_;
    my @sql;
    foreach my $old_i ( $p{old}->indexes )
    {
        unless ( eval { $p{new}->index( $old_i->id ) } )
        {
            push @sql, $self->drop_index_sql($old_i, $p{new}->name)
                if eval { $p{new}->columns( map { $_->name } $old_i->columns ) } && ! $@;
        }
    }

    my %changed_name;
    foreach my $new_c ( $p{new}->columns )
    {
        $changed_name{ $new_c->former_name } = 1
            if defined $new_c->former_name && $new_c->former_name ne $new_c->name;
    }

    foreach my $old_c ( $p{old}->columns )
    {
        unless ( $changed_name{ $old_c->name } ||
                 ( my $new_c = eval { $p{new}->column( $old_c->name ) } )
               )
        {
            push @sql, $self->drop_column_sql( new_table => $p{new},
                                               old => $old_c );
        }
    }

    foreach my $new_c ( $p{new}->columns )
    {
        # When syncing against an existing schema, the column may be
        # present with its new name.
        my $old_c;
        if ( defined $new_c->former_name )
        {
            $old_c = eval { $p{old}->column( $new_c->former_name ) };
        }

        $old_c ||= eval { $p{old}->column( $new_c->name ) };

        if ($old_c)
        {
            if ( $old_c->name ne $new_c->name )
            {
                if ( $self->can_alter_column_name )
                {
                    push @sql, $self->alter_column_name_sql($new_c);
                }
                else
                {
                    # no need to do more because table will be
                    # recreated from scratch
                    recreate_table_exception();
                }
            }

            push @sql, $self->column_sql_diff( new => $new_c,
                                               old => $old_c,
                                             );
        }
        else
        {
            push @sql, $self->column_sql_add($new_c);
        }
    }

    foreach my $new_i ( $p{new}->indexes )
    {
        if ( my $old_i = eval { $p{old}->index( $new_i->id ) } )
        {
            push @sql, $self->index_sql_diff( new => $new_i,
                                              old => $old_i );
        }
        else
        {
            push @sql, $self->index_sql($new_i)
        }
    }

    foreach my $new_fk ( $p{new}->all_foreign_keys )
    {
        unless ( grep { $new_fk->id eq $_->id } $p{old}->all_foreign_keys )
        {
            push @{ $self->{state}{deferred_sql} }, $self->foreign_key_sql($new_fk)
        }
    }

    foreach my $old_fk ( $p{old}->all_foreign_keys )
    {
        unless ( grep { $old_fk->id eq $_->id } $p{new}->all_foreign_keys )
        {
            push @sql, $self->drop_foreign_key_sql($old_fk);
        }
    }

    my $pk_changed;
    foreach my $old_pk ( $p{old}->primary_key )
    {
        next if $changed_name{ $old_pk->name };

        my $new_col = eval { $p{new}->column( $old_pk->name ) };
        unless ( $new_col && $new_col->is_primary_key )
        {
            push @sql, $self->alter_primary_key_sql( new => $p{new},
                                                     old => $p{old} );

            $pk_changed = 1;
            last;
        }
    }

    unless ($pk_changed)
    {
        foreach my $new_pk ( $p{new}->primary_key )
        {
            my $old_col = eval { $p{old}->column( $new_pk->name ) };

            next if $new_pk->former_name && $changed_name{ $new_pk->former_name };

            unless ( $old_col && $old_col->is_primary_key )
            {
                push @sql, $self->alter_primary_key_sql( new => $p{new},
                                                         old => $p{old} );

                last;
            }
        }
    }

    my $alter_attributes;
    foreach my $new_att ( $p{new}->attributes )
    {
        unless ( $p{old}->has_attribute( attribute => $new_att, case_sensitive => 1 ) )
        {
            $alter_attributes = 1;

            push @sql, $self->alter_table_attributes_sql( new => $p{new},
                                                          old => $p{old},
                                                        );

            last;
        }
    }

    unless ($alter_attributes)
    {
        foreach my $old_att ( $p{old}->attributes )
        {
            unless ( $p{new}->has_attribute( attribute => $old_att, case_sensitive => 1 ) )
            {
                $alter_attributes = 1;

                push @sql, $self->alter_table_attributes_sql( new => $p{new},
                                                              old => $p{old},
                                                            );

                last;
            }
        }
    }

    return @sql;
}


sub _virtual
{
    my $self = shift;

    my $sub = (caller(1))[3];
    Alzabo::Exception::VirtualMethod->throw( error =>
                                             "$sub is a virtual method and must be subclassed in " . ref $self );
}

__END__

=head1 NAME

Alzabo::RDBMSRules - Base class for Alzabo RDBMS rulesets

=head1 SYNOPSIS

  use Alzabo::RDBMSRules;

  my $rules = Alzabo::RDBMSRules( rules => 'MySQL' );

=head1 DESCRIPTION

This class is the base class for all C<Alzabo::RDBMSRules> modules.
To instantiate a subclass call this class's C<new()> method.  See the
L<SUBCLASSING Alzabo::RDBMSRules> section for information on how to
make a ruleset for the RDBMS of your choice.

=head1 METHODS

=head2 available

A list of names representing the available C<Alzabo::RDBMSRules>
subclasses.  Any one of these names would be appropriate as the
"rdbms" parameter for the L<C<< Alzabo::RDBMSRules->new()
>>|Alzabo::RDBMSRules/new> method.

=head2 new

The constructor always accepts one parameter, "rdbms", which is the
name of the RDBMS to be used.

Some subclasses may accept additional values.

The constructor returns a new C<Alzabo::RDBMSRules> object of the
appropriate subclass.

Throws: L<C<Alzabo::Exception::Eval>|Alzabo::Exceptions>

=head2 schema_sql (C<Alzabo::Create::Schema> object)

Returns a list of SQL statements which would create the given schema.

=head2 index_sql (C<Alzabo::Create::Index> object)

Returns a list of SQL statements to create the specified index.

=head2 drop_table_sql (C<Alzabo::Create::Table> object)

Returns a list of SQL statements to drop the specified table.

=head2 drop_index_sql (C<Alzabo::Create::Index> object)

Returns a list of SQL statements to drop the specified index.

=head2 schema_sql_diff

This method takes two parameters:

=over 4

=item * new => C<Alzabo::Create::Schema> object

=item * old => C<Alzabo::Create::Schema> object

=back

This method compares the two schema objects and returns an array of
SQL statements which turn the "old" schema into the "new" one.

=head2 table_sql_diff

This method takes two parameters:

=over 4

=item * new => C<Alzabo::Create::Table> object

=item * old => C<Alzabo::Create::Table> object

=back

This method compares the two table objects and returns an array of
SQL statements which turn the "old" table into the "new" one.

=head2 type_is_numeric (C<Alzabo::Column> object)

Returns a boolean indicating whether or not the column is numeric
(integer or floating point).

=head2 quote_identifiers

Returns true or false to indicate whether or not the generated DDL SQL
statements should have their identifiers quoted or not.  This may be
overridden by subclasses.  It defaults to false.

=head2 can_alter_table_name

If this is true, then when syncing a schema, the object will call
C<alter_table_name_sql()> to change the table's name.  Otherwise it
will call C<recreate_table_sql()>.

=head2 can_alter_column_name

If this is true, then when syncing a schema, the object will call
C<alter_column_name_sql()> to change the table's name.  Otherwise it
will call C<recreate_table_sql()>.

=head2 Virtual Methods

The following methods are not implemented in the C<Alzabo::RDBMSRules>
class itself and must be implemented in its subclasses.

=head2 column_types

Returns a list of valid column types.

=head2 feature ($feature)

Given a string defining a feature, this method indicates whether or
not the given RDBMS supports that feature.  By default, this method
always returns false unless overridden in the subclass.

Features that may be asked for:

=over 4

=item * extended_column_types

Column types that must be input directly from a user, as opposed to
being chosen from a list.  MySQL's ENUM and SET types are examples of
such types.

=item * index_column_prefixes

MySQL supports the notion of column prefixes in indexes, allowing you
to index only a portion of a large text column.

=item * fulltext_indexes

This should be self-explanatory.

=item * functional_indexes

Indexes on functions, as supported by PostgreSQL.

=back

=head2 validate_schema_name (C<Alzabo::Schema> object)

Throws an L<C<Alzabo::Exception::RDBMSRules>|Alzabo::Exceptions> if
the schema's name is not valid.

=head2 validate_table_name (C<Alzabo::Create::Table> object)

Throws an L<C<Alzabo::Exception::RDBMSRules>|Alzabo::Exceptions> if
the table's name is not valid.

=head2 validate_column_name (C<Alzabo::Create::Column> object)

Throws an L<C<Alzabo::Exception::RDBMSRules>|Alzabo::Exceptions> if
the column's name is not valid.

=head2 validate_column_type ($type_as_string)

Throws an L<C<Alzabo::Exception::RDBMSRules>|Alzabo::Exceptions> if
the type is not valid.

This method returns a canonized version of the type.

=head2 validate_column_length (C<Alzabo::Create::Column> object)

Throws an L<C<Alzabo::Exception::RDBMSRules>|Alzabo::Exceptions> if
the length or precision is not valid for the given column.

=head2 validate_column_attribute

This method takes two parameters:

=over 4

=item * column => C<Alzabo::Create::Column> object

=item * attribute => $attribute

=back

This method is a bit different from the others in that it takes an
existing column object and a B<potential> attribute.

It throws an L<C<Alzabo::Exception::RDBMSRules>|Alzabo::Exceptions> if
the attribute is is not valid for the column.

=head2 validate_primary_key (C<Alzabo::Create::Column> object)

Throws an L<C<Alzabo::Exception::RDBMSRules>|Alzabo::Exceptions> if
the column is not a valid primary key for its table.

=head2 validate_sequenced_attribute (C<Alzabo::Create::Column> object)

Throws an L<C<Alzabo::Exception::RDBMSRules>|Alzabo::Exceptions> if
the column cannot be sequenced.

=head2 validate_index (C<Alzabo::Create::Index> object)

Throws an L<C<Alzabo::Exception::RDBMSRules>|Alzabo::Exceptions> if
the index is not valid.

=head2 table_sql (C<Alzabo::Create::Table> object)

Returns an array of SQL statements to create the specified table.

=head2 column_sql (C<Alzabo::Create::Column> object)

Returns an array of SQL statements to create the specified column.

=head2 foreign_key_sql (C<Alzabo::Create::ForeignKey> object)

Returns an array of SQL statements to create the specified foreign
key.

=head2 drop_column_sql (C<Alzabo::Create::Column> object)

Returns an array of SQL statements to drop the specified column.

=head2 drop_foreign_key_sql (C<Alzabo::Create::ForeignKey> object)

Returns an array of SQL statements to drop the specified foreign key.

=head2 column_sql_add (C<Alzabo::Create::Column> object)

Returns an array of SQL statements to add the specified column.

=head2 column_sql_diff

This method takes two parameters:

=over 4

=item * new => C<Alzabo::Create::Column> object

=item * old => C<Alzabo::Create::Column> object

=back

This method compares the two table objects and returns an array of
SQL statements which turn the "old" table into the "new" one.

=head2 index_sql_diff

This method takes two parameters:

=over 4

=item * new => C<Alzabo::Create::Index> object

=item * old => C<Alzabo::Create::Index> object

=back

This method compares the two index objects and returns an array of
SQL statements which turn the "old" index into the "new" one.

=head2 alter_primary_key_sql

This method takes two parameters:

=over 4

=item * new => C<Alzabo::Create::Table> object

=item * old => C<Alzabo::Create::Table> object

=back

This method compares the two table objects and returns an array of SQL
statements which alter the "old" one's primary key to match the "new"
one's.

=head2 alter_table_name_sql (C<Alzabo::Create::Table> object)

Given a table, this method is expected to change the table's name from
C<< $table->former_name >> to C<< $table->name >>.  This will only be
called if the rules object returns true for C<can_alter_table_name()>.

=head2 alter_column_name_sql (C<Alzabo::Create::Table> object)

Given a column, this method is expected to change the table's name
from C<< $column->former_name >> to C<< $column->name >>.  This will
only be called if the rules object returns true for
C<can_alter_column_name()>.

=head2 recreate_table_sql

This method takes two parameters:

=over 4

=item * new => C<Alzabo::Create::Table> object

=item * old => C<Alzabo::Create::Table> object

=back

This method is expected to drop the old table and create the new one.

However, it B<must> preserve all the data stored in the old table,
excluding data in columns that are being dropped.  Additionally, if
there are sequences associated with columns in the old table, they
should not be dropped.

This method will only be called if either C<can_alter_table_name()> or
C<can_alter_column_name()> return false.

=head2 reverse_engineer (C<Alzabo::Create::Schema> object)

Given a schema object (which presumably has no tables), this method
uses the schema's L<C<Alzabo::Driver>|Alzabo::Driver> object to
connect to an existing database and reverse engineer it into the
appropriate Alzabo objects.

=head2 type_is_integer (C<Alzabo::Column> object)

Returns a boolean indicating whether or not the column is an integer
type.

=head2 type_is_floating_point (C<Alzabo::Column> object)

Returns a boolean indicating whether or not the column is a floating
point type.

=head2 type_is_character (C<Alzabo::Column> object)

Returns a boolean indicating whether or not the column is a character
type.  This is defined as any type which is defined to store text,
regardless of length.

=head2 type_is_date (C<Alzabo::Column> object)

Returns a boolean indicating whether or not the column is a date type.
This is B<not> true for datetime types.

=head2 type_is_datetime (C<Alzabo::Column> object)

Returns a boolean indicating whether or not the column is a datetime
type.  This is B<not> true for date types.

=head2 type_is_time (C<Alzabo::Column> object)

Returns a boolean indicating whether or not the column is a time type.
This is B<not> true for datetime types.

=head2 type_is_time_interval (C<Alzabo::Column> object)

Returns a boolean indicating whether or not the column is a time
interval type.

=head1 SUBCLASSING Alzabo::RDBMSRules

To create a subclass of C<Alzabo::RDBMSRules> for your particular
RDBMS is fairly simple.

Here's a sample header to the module using a fictional RDBMS called
FooDB:

 package Alzabo::RDBMSRules::FooDB;

 use strict;
 use vars qw($VERSION);

 use Alzabo::RDBMSRules;

 use base qw(Alzabo::RDBMSRules);

The next step is to implement a C<new()> method and the methods listed
under the section L<Virtual Methods>.  The new method should look a
bit like this:

 1:  sub new
 2:  {
 3:      my $proto = shift;
 4:      my $class = ref $proto || $proto;
 5:      my %p = @_;
 6:
 7:      my $self = bless {}, $self;
 8:
 9:      return $self;
 10:  }

The hash %p contains any values passed to the
L<C<Alzabo::RDBMSRules-E<gt>new>|Alzabo::RDBMSRules/new> method by its
caller.

Lines 1-7 should probably be copied verbatim into your own C<new>
method.  Line 5 can be deleted if you don't need to look at the
parameters.

The rest of your module should simply implement the methods listed
under the L<Virtual Methods> section of this documentation.

Look at the included C<Alzabo::RDBMSRules> subclasses for examples.
Feel free to contact me for further help if you get stuck.  Please
tell me what database you're attempting to implement, and include the
code you've written so far.

=head1 AUTHOR

Dave Rolsky, <dave@urth.org>

=cut
