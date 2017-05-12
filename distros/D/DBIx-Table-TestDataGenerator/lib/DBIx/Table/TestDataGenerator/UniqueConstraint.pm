package DBIx::Table::TestDataGenerator::UniqueConstraint;
use Moo;

use strict;
use warnings;

our $VERSION = "0.005";
$VERSION = eval $VERSION;

use Carp;

use List::Util qw / first /;

use aliased 'DBIx::Table::TestDataGenerator::DBIxHelper';
use aliased 'DBIx::Table::TestDataGenerator::DataType';
use aliased 'DBIx::Table::TestDataGenerator::Query';
use aliased 'DBIx::Table::TestDataGenerator::Increment';

has schema => (
    is       => 'ro',
    required => 1,
);

has table => (
    is       => 'ro',
    required => 1,
);

has unique_cols_to_incr => (
    is       => 'rw',
    default  => sub { return {} },
    init_arg => undef,
);

has pkey_is_auto_increment => (
    is       => 'rw',
    default  => sub { return 0 },
    init_arg => undef,
);

has type_preference_for_incrementing => (
    is       => 'rw',
    init_arg => undef,
);

has pkey_col_names => (
    is       => 'ro',
    default  => sub { return [] },
    init_arg => undef,
);

has pkey_col => (
    is       => 'rw',
    init_arg => undef,
);

has pkey_col_incrementor => (
    is       => 'rw',
    init_arg => undef,
);

sub BUILD {
    my ($self) = @_;

    #Handle unique constraints

    my $unique_cols_info =
      $self->unique_columns_with_max( $self->schema, $self->table, 0 );

    #For each unique constraint we determine a column whose value will
    #be incremented on each insert into the target table. The Increment class
    #influences which column will be selected by defining an order on data
    #types.
    #For the selected column, a (data type dependent) incrementor is provided
    #by the Increment class.
    $self->type_preference_for_incrementing(
        Increment->get_type_preference_for_incrementing() );

    for my $constraint_name ( keys %{$unique_cols_info} ) {
        my %constraint_info = %{ $unique_cols_info->{$constraint_name} };
        my $selected_data_type =
          first { $constraint_info{$_} }
        @{ $self->type_preference_for_incrementing };
        croak "Could not handle unique constraint $constraint_name, "
          . 'Don\'t know how to increment columns of any '
          . 'of the constrained columns\' data types.'
          unless defined $selected_data_type;
        my ( $selected_unique_col, $max ) =
          @{ @{ $constraint_info{$selected_data_type} }[0] };
        $self->unique_cols_to_incr->{$selected_unique_col} =
          Increment->get_incrementor( $selected_data_type, $max );
    }

    #Handle primary key constraint

    #Determine the dictionary pkey->datatype(pkey) of the pkey columns.
    my %pkey_cols_info =
      %{ $self->unique_columns_with_max( $self->schema, $self->table, 1 ) };

    #Determine the column names in the primary key. This is needed only
    #for determining later on if there is a self-reference.

    if (%pkey_cols_info) {

        #Note: there can only be one primary key, we can therefore
        #select the first element of %pkey_cols_info:
        my $constraint_name = ( keys %pkey_cols_info )[0];
        my %constraint_info = %{ $pkey_cols_info{$constraint_name} };

        for my $data_type ( keys %constraint_info ) {
            for my $col_infos ( $constraint_info{$data_type} ) {
                for my $col_info ( @{$col_infos} ) {
                    push @{ $self->pkey_col_names }, @{$col_info}[0];
                }
            }
        }

        #Check if we have an auto-increment column and if this is that case,
        #that it is in the primary key
        my $pkey_auto =
          $self->get_auto_increment_pkey_col( $self->schema, $self->table,
            $self->pkey_col_names );

        #If we have (exactly one) auto-increment column in the primary key,
        #this will be the column to be increased (automatically)
        if ($pkey_auto) {
            $self->pkey_is_auto_increment(1);
            $self->pkey_col($pkey_auto);
        }
        else {
            #Determine the pkey column to be incremented and its incrementor
            #similar logic as for unique constraint columns.
            my $selected_data_type =
              first { $constraint_info{$_} }
            @{ $self->type_preference_for_incrementing };
            croak "Could not handle primary key constraint $constraint_name."
              unless defined $selected_data_type;

            my ( $p, $max ) =
              @{ @{ $constraint_info{$selected_data_type} }[0] };
            $self->pkey_col($p);
            $self->pkey_col_incrementor(
                Increment->get_incrementor( $selected_data_type, $max ) );
        }
    }
    return;
}

#todo: improve function, e.g. for SQLite there is no datetime data type,
#instead, "text" is used as the data type, this leads to nonsense values
sub unique_columns_with_max {
    my ( $self, $schema, $table, $handle_pkey ) = @_;
    my $result_class = DBIxHelper->get_result_class( $schema, $table );
    my $src          = $schema->source($result_class);
    my %constraints  = $src->unique_constraints();

    my %unique_with_max;
    foreach my $constraint_name ( keys %constraints ) {
        next
          unless ( $handle_pkey && $constraint_name eq 'primary'
            || !$handle_pkey && $constraint_name ne 'primary' );

        my %constr_info;
        my @cols = @{ $constraints{$constraint_name} };

        foreach my $col_name (@cols) {

            #note: column types are converted to upper case to simplify
            #comparisons later on
            my $col_type = uc ${ $src->column_info($col_name) }{data_type};
            my $is_text  = DataType->is_text($col_type);
            my $col_max;
            if ($is_text) {
                $col_max =
                  Query->max_length( $schema, $col_name, $result_class );
            }
            else {
                $col_max =
                  Query->max_value( $schema, $col_name, $result_class );
            }

            $constr_info{$col_type} //= [];
            push @{ $constr_info{$col_type} }, [ $col_name, $col_max ];
        }
        $unique_with_max{$constraint_name} = \%constr_info;
    }
    return \%unique_with_max;
}

#we only allow a single auto increment column and it must be part of the
#primary key
sub get_auto_increment_pkey_col {
    my ( $self, $schema, $table, $pkey_col_names ) = @_;
    my $result_class = DBIxHelper->get_result_class( $schema, $table );
    my $src          = $schema->source($result_class);
    my @cols         = $result_class->columns;
    my @auto_increment_cols;
    foreach my $col_name (@cols) {
        if ( ${ $src->column_info($col_name) }{is_auto_increment} ) {
            croak 'auto-increment columns only allowed in primary key'
              unless grep { $_ eq $col_name } @{$pkey_col_names};
            push @auto_increment_cols, $col_name;
        }
    }

    croak 'cannot handle more than one auto-increment column in primary key ('
      . join( ', ', @auto_increment_cols ) . ')'
      if @auto_increment_cols > 1;

    if ( @auto_increment_cols == 1 ) {
        return $auto_increment_cols[0];
    }

    return;
}

1;    # End of DBIx::Table::TestDataGenerator::UniqueConstraint

__END__

=pod

=head1 NAME

DBIx::Table::TestDataGenerator::UniqueConstraint - unique constraint information

=head1 DESCRIPTION

This class determines information about unique key constraints defined on the target table, in particular about the primary key.

=head1 SUBROUTINES/METHODS

=head2 schema

Accessor for the DBIx::Class schema for the target database, required constructor argument.

=head2 table

Accessor for target table, required constructor argument.

=head2 pkey_col_incrementor

Accessor for the method to be used to increment the primary key column chosen to be incremented, externally read-only.

=head2 pkey_col

Accessor for the name of the primary key column to be incremented, externally read-only.

=head2 pkey_col_names

Accessor for a reference to an array containing the names of the primary key columns, externally read-only.

=head2 type_preference_for_incrementing

Accessor for a reference to an array containing a list of SQL data type names sorted descendingly by the priority in which columns of the corresponding type will get selected for incrementing, externally read-only.

=head2 unique_cols_to_incr

Accessor for a reference to an array containing the names of the columns in unique constraints which will be increased for new records, externally read-only.

=head2 pkey_is_auto_increment

Accessor which is true if the corresponding primary key column is auto-increment and false otherwise, externally read-only.

=head2 BUILD

Arguments: none.

Determines information about the unique constraints on the target table.

=head2 unique_columns_with_max

Arguments:

=over 4

=item * schema: DBIx::Class schema

=item * table: name of target table

=item * handle_pkey: if true, determines information about the primary key constraint, otherwise about the other unique constraints

=back

In case handle_pkey is false, this method returns a hash reference of the following structure:

  {
      UNIQUE_CONSTR_1 =>
      {
        DATA_TYPE_1 => [ [ COL_NAME_1, MAX_VAL_1 ], ..., [COL_NAME_N, MAX_VAL_N] ],
        DATA_TYPE_2 => [ [ COL_NAME_N+1, MAX_VAL_N+1 ], ..., [COL_NAME_M, MAX_VAL_M] ],
        ...
      }
      UNIQUE_CONSTR_2 => {...}
    ...
  }

Here, the keys of the base hash are the names of all uniqueness constraints. For each such constraint, the value of the base hash is another hash having as values all the data types used for columns in the constraint and as values an array reference where each element is a pair (column_name, max_value) where column_name runs over all column names in the constraint and max_value is the corresponding current maximum value. (Please note the comment in the description of get_incrementor on how we currently determine this maximum in case of string data types.)

In case handle_pkey is true, the corresponding information is returned for the primary key constraint, in particular the base hash has only one key as there may be only one primary key constraint:

  {
      PRIMARY_KEY_NAME =>
      {
        DATA_TYPE_1 => [ [ COL_NAME_1, MAX_VAL_1 ], ..., [COL_NAME_N, MAX_VAL_N] ],
        DATA_TYPE_2 => [ [ COL_NAME_N+1, MAX_VAL_N+1 ], ..., [COL_NAME_M, MAX_VAL_M] ],
        ...
      }
  }
  
=head2 get_auto_increment_pkey_col

Arguments:

=over 4

=item * schema: DBIx::Class schema

=item * table: name of target table

=back

Checks if we have an auto-increment column. If we have one and it is not part of the primary key, we abort, otherwise, pkey_is_auto_increment is set to true.

=head2 get_random_pkey_val

This method is for handling an auto-increment primary key column when root nodes have pkey = referenced pkey and the referencing column does not allow null values. Since in this case we define a Row object and use it to retrieve the auto-increment value, i.e. the pkey value is not known beforehand, we need to pass a non-null value for the referencing column. The current method returns a valid temporary value.

=head1 AUTHOR

Jose Diaz Seng, C<< <josediazseng at gmx.de> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012-2013, Jose Diaz Seng.

This module is free software; you can redistribute it and/or modify it under the same terms as Perl 5.10.0. For more details, see the full text of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but without any warranty; without even the implied warranty of merchantability or fitness for a particular purpose. 
