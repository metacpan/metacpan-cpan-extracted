package DBIx::DBSchema::ForeignKey;

use strict;

our $VERSION = '0.13';
our $DEBUG = 0;

=head1 NAME

DBIx::DBSchema::ForeignKey - Foreign key objects

=head1 SYNOPSIS

  use DBIx::DBSchema::ForeignKey;

  $foreign_key = new DBIx::DBSchema::ForeignKey (
    { 'columns' => [ 'column_name' ],
      'table'   => 'foreign_table',
    }
  );

  $foreign_key = new DBIx::DBSchema::ForeignKey (
    {
      'constraint' => 'constraint_name',
      'columns'    => [ 'column_name', 'column2' ],
      'table'      => 'foreign_table',
      'references' => [ 'foreign_column', 'foreign_column2' ],
      'match'      => 'MATCH FULL', # or MATCH SIMPLE
      'on_delete'  => 'NO ACTION', # on clauses: NO ACTION / RESTRICT /
      'on_update'  => 'RESTRICT',  #           CASCADE / SET NULL / SET DEFAULT
    }
  );

=head1 DESCRIPTION

DBIx::DBSchema::ForeignKey objects represent a foreign key.

=head1 METHODS

=over 4

=item new HASHREF | OPTION, VALUE, ...

Creates a new DBIx::DBschema::ForeignKey object.

Accepts either a hashref or a list of options and values.

Options are:

=over 8

=item constraint - constraint name

=item columns - List reference of column names

=item table - Foreign table name

=item references - List reference of column names in foreign table

=item match - 

=item on_delete - 

=item on_update - 

=back

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my %opt = ref($_[0]) ? %{$_[0]} : @_; #want a new reference
  my $self = \%opt;
  bless($self, $class);
}

=item constraint [ CONSTRAINT_NAME ]

Returns or sets the constraint name

=cut

sub constraint {
  my($self, $value) = @_;
  if ( defined($value) ) {
    $self->{constraint} = $value;
  } else {
    $self->{constraint};
  }
}

=item table [ TABLE_NAME ]

Returns or sets the foreign table name

=cut

sub table {
  my($self, $value) = @_;
  if ( defined($value) ) {
    $self->{table} = $value;
  } else {
    $self->{table};
  }
}

=item columns [ LISTREF ]

Returns or sets the columns.

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

=item references [ LISTREF ]

Returns or sets the referenced columns.

=cut

sub references {
  my($self, $value) = @_;
  if ( defined($value) ) {
    $self->{references} = $value;
  } else {
    $self->{references};
  }
}

=item references_sql

Returns a comma-joined list of referenced columns, suitable for an SQL
statement.

=cut

sub references_sql {
  my $self = shift;
  join(', ', @{ $self->references || $self->columns } );
}

=item match [ TABLE_NAME ]

Returns or sets the MATCH clause

=cut

sub match {
  my($self, $value) = @_;
  if ( defined($value) ) {
    $self->{match} = $value;
  } else {
    defined($self->{match}) ? $self->{match} : '';
  }
}

=item on_delete [ ACTION ]

Returns or sets the ON DELETE clause

=cut

sub on_delete {
  my($self, $value) = @_;
  if ( defined($value) ) {
    $self->{on_delete} = $value;
  } else {
    defined($self->{on_delete}) ? $self->{on_delete} : '';
  }
}

=item on_update [ ACTION ]

Returns or sets the ON UPDATE clause

=cut

sub on_update {
  my($self, $value) = @_;
  if ( defined($value) ) {
    $self->{on_update} = $value;
  } else {
    defined($self->{on_update}) ? $self->{on_update} : '';
  }
}

=item sql_foreign_key

Returns an SQL FOREIGN KEY statement.

=cut

sub sql_foreign_key {
  my( $self ) = @_;

  my $table = $self->table;
  my $col_sql = $self->columns_sql;
  my $ref_sql = $self->references_sql;

  "FOREIGN KEY ( $col_sql ) REFERENCES $table ( $ref_sql ) ".
    join ' ', map { (my $thing_sql = uc($_) ) =~ s/_/ /g;
                    "$thing_sql ". $self->$_;
                  }
                grep $self->$_, qw( match on_delete on_update );
}

=item cmp OTHER_INDEX_OBJECT

Compares this object to another supplied object.  Returns true if they are
have the same table, columns and references.

=cut

sub cmp {
  my( $self, $other ) = @_;

  $self->table eq $other->table
    and $self->columns_sql    eq $other->columns_sql
    and $self->references_sql eq $other->references_sql
    and uc($self->match)      eq uc($other->match)
    and uc($self->on_delete)  eq uc($other->on_delete)
    and uc($self->on_update)  eq uc($other->on_update)
  ;
}

=back

=head1 AUTHOR

Ivan Kohler <ivan-dbix-dbschema@420.am>

Copyright (c) 2013 Freeside Internet Services, Inc.
All rights reserved.
This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 BUGS

Should give in and Mo or Moo.

=head1 SEE ALSO

L<DBIx::DBSchema::Table>, L<DBIx::DBSchema>, L<DBI>

=cut

1;


