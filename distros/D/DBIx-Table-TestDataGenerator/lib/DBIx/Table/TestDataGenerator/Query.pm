package DBIx::Table::TestDataGenerator::Query;
use Moo;

use strict;
use warnings;

our $VERSION = "0.005";
$VERSION = eval $VERSION;

use Carp;

use aliased 'DBIx::Table::TestDataGenerator::DBIxHelper';

use Readonly;
Readonly my $COMMA         => q{,};
Readonly my $QUESTION_MARK => q{?};

sub num_records {
    my ( $self, $schema, $table ) = @_;
    $table = uc $table;
    my $cls = DBIxHelper->get_result_class( $schema, $table );
    return $schema->resultset($cls)->count;
}

sub max_value {
    my ( $self, $schema, $col_name, $result_class ) = @_;
    return $schema->resultset($result_class)->search()
      ->get_column($col_name)->max();
}

sub max_length {
    my ( $self, $schema, $col_name, $result_class ) = @_;
    my @vals =
      $schema->resultset($result_class)->search()->get_column($col_name)
      ->func('LENGTH');
    return ( reverse sort @vals )[0];
}

sub insert_statement {
    my ( $self, $table, $colname_array_ref ) = @_;
    my $all_cols = join $COMMA, @{$colname_array_ref};
    my $placeholders = join $COMMA,
      ($QUESTION_MARK) x ( 0 + @{$colname_array_ref} );
    return "INSERT INTO $table ($all_cols) VALUES ($placeholders)";
}

sub prepare_insert {
    my ( $self, $dbh, $table, $colname_array_ref ) = @_;
    my $result = eval {
        $dbh->prepare( $self->insert_statement( $table, $colname_array_ref ) );
    };

    if ($@) {
        carp "prepare failed because $@";
        eval { $dbh->rollback() };
    }
    return $result;
}

sub execute_insert {
    my ( $self, $dbh, $sth_insert, $all_vals ) = @_;
    eval { $sth_insert->execute( @{$all_vals} ); };
    if ($@) {
        carp "execute_insert failed because $@";
        eval { $dbh->rollback() };
    }
    return;
}

sub execute_new_row {
    my ( $self, $schema, $table, $cols_and_values ) = @_;
    my $cls = DBIxHelper->get_result_class( $schema, $table );
    my $row = $schema->resultset($cls)->new($cols_and_values);
    $row->insert();
    return $row;
}

sub commit {
    my ( $self, $dbh ) = @_;
    eval { $dbh->commit(); };

    if ($@) {
        carp "commit failed because $@";
        eval { $dbh->rollback() };
    }
}

sub disconnect {
    my ( $self, $dbh ) = @_;
    eval { $dbh->disconnect(); };

    if ($@) {
        carp "disconnect failed because $@";
    }
    return;
}

1;    # End of DBIx::Table::TestDataGenerator::Query

__END__

=pod

=head1 NAME

DBIx::Table::TestDataGenerator::Query - query database and handle SQL commands

=head1 DESCRIPTION

The class provides methods querying the target database for data and the ones handling SQL commands (indirectly via DBIx::Class modules).

=head1 SUBROUTINES/METHODS

=head2 num_records

Arguments:

=over 4

=item * schema: DBIx::Class schema

=item * table: name of the target table

=back

Returns the number of records in the target table.

=head2 max_value

Arguments:

=over 4

=item * schema: DBIx::Class schema

=item * col_name: name of the target column

=item * result_class: result class involving the target column

=back

Returns the maximum value of the passed in column.

=head2 max_length

Arguments:

=over 4

=item * schema: DBIx::Class schema

=item * col_name: name of the target column

=item * result_class: result class involving the target column

=back

Returns the maximum length of the passed in column.

=head2 insert_statement

Arguments:

=over 4

=item * table: name of the target table

=item * colname_array_ref: reference to the complete array of column names of the target table

=back

Returns a string defining a parametrized insert statement for the target table.

=head2 prepare_insert

Arguments:

=over 4

=item * dbh: DBI database handle

=item * table: name of the target table

=item * colname_array_ref: reference to the complete array of column names of the target table

=back

Prepares an insert statement.

=head2 execute_insert

Arguments:

=over 4

=item * sth_insert: handle of a prepared insert statement

=item * all_vals: the values to be used for the insert statement

=back

Executes an insert statement.

=head2 execute_new_row

Arguments:

=over 4

=item * schema: DBIx::Class schema

=item * table: name of the target table

=item * cols_and_values: reference to a hash having as keys column names of the target table and as values corresponding values.

=back

Adds a new row to the target table. Is used in case we have an auto-increment column, there is a self-reference and the root nodes are identified by having "pkey = referenced pkey". In this case, we need to know the value of the auto-increment column for the new record and this can easily be determined from the DBIx::Class::Row object itself. For performance reasons, we don't use Row objects for the other inserts, in those cases, we use plain DBI.

=head2 commit

Argument: DBI database handle.

Executes a commit.

=head2 disconnect

Argument: DBI database handle.

Disconnects from the target database.

=head1 AUTHOR

Jose Diaz Seng, C<< <josediazseng at gmx.de> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012-2013, Jose Diaz Seng.

This module is free software; you can redistribute it and/or modify it under the same terms as Perl 5.10.0. For more details, see the full text of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but without any warranty; without even the implied warranty of merchantability or fitness for a particular purpose.
