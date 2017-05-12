package DBIx::DBSchema::Index;

use strict;
use vars qw($VERSION $DEBUG);

$VERSION = 0.1;
$DEBUG = 0;

=head1 NAME

DBIx::DBSchema::Index - Index objects

=head1 SYNOPSYS

  use DBIx::DBSchema::Index;

  $index = new DBIx::DBSchema::Index (
    {
    }
  );

=head1 DESCRIPTION

DBIx::DBSchema::Index objects represent a unique or non-unique database index.

=head1 METHODS

=over 4

=item new HASHREF | OPTION, VALUE, ...

Creates a new DBIx::DBschema::Index object.

Accepts either a hashref or a list of options and values.

Options are:

=over 8

=item name - Index name

=item using - Optional index method

=item unique - Boolean indicating whether or not this is a unique index.

=item columns - List reference of column names (or expressions)

=back

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my %opt = ref($_[0]) ? %{$_[0]} : @_; #want a new reference
  my $self = \%opt;
  bless($self, $class);
}

=item name [ INDEX_NAME ]

Returns or sets the index name.

=cut

sub name {
  my($self, $value) = @_;
  if ( defined($value) ) {
    $self->{name} = $value;
  } else {
    $self->{name};
  }
}

=item using [ INDEX_METHOD ]

Returns or sets the optional index method.

=cut

sub using {
  my($self, $value) = @_;
  if ( defined($value) ) {
    $self->{using} = $value;
  } else {
    defined($self->{using})
      ? $self->{using}
      : '';
  }
}

=item unique [ BOOL ]

Returns or sets the unique flag.

=cut

sub unique {
  my($self, $value) = @_;
  if ( defined($value) ) {
    $self->{unique} = $value;
  } else {
    #$self->{unique};
    $self->{unique} ? 1 : 0;
  }
}

=item columns [ LISTREF ]

Returns or sets the indexed columns (or expressions).

=cut

sub columns {
  my($self, $value) = @_;
  if ( defined($value) ) {
    $self->{columns} = $value;
  } else {
    $self->{columns};
  }
}

=item columns_sql

Returns a comma-joined list of columns, suitable for an SQL statement.

=cut

sub columns_sql {
  my $self = shift;
  join(', ', @{ $self->columns } );
}

=item sql_create_index TABLENAME

Returns an SQL statment to create this index on the specified table.

=cut

sub sql_create_index {
  my( $self, $table ) = @_;

  my $unique = $self->unique ? 'UNIQUE' : '';
  my $name = $self->name;
  my $col_sql = $self->columns_sql;

  "CREATE $unique INDEX $name ON $table ( $col_sql )";
}

=item cmp OTHER_INDEX_OBJECT

Compares this object to another supplied object.  Returns true if they are
identical, or false otherwise.

=cut

sub cmp {
  my( $self, $other ) = @_;

  $self->name eq $other->name and $self->cmp_noname($other);
}

=item cmp_noname OTHER_INDEX_OBJECT

Compares this object to another supplied object.  Returns true if they are
identical, disregarding index name, or false otherwise.

=cut

sub cmp_noname {
  my( $self, $other ) = @_;

      $self->using       eq $other->using
  and $self->unique      == $other->unique
  and $self->columns_sql eq $other->columns_sql;

}

=back

=head1 AUTHOR

Ivan Kohler <ivan-dbix-dbschema@420.am>

Copyright (c) 2007 Ivan Kohler
Copyright (c) 2007 Freeside Internet Services, Inc.
All rights reserved.
This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 BUGS

Is there any situation in which sql_create_index needs to return a list of
multiple statements?

=head1 SEE ALSO

L<DBIx::DBSchema::Table>, L<DBIx::DBSchema>, L<DBI>

=cut

1;


