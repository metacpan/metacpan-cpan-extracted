package DBIx::Table::TestDataGenerator::Randomize;
use Moo;

use strict;
use warnings;

our $VERSION = "0.005";
$VERSION = eval $VERSION;

use Carp;

use aliased 'DBIx::Table::TestDataGenerator::DBIxHelper';
use DBIx::Table::TestDataGenerator::ResultSetWithRandom;

sub random_record {
    my ( $self, $schema, $table, $colname_list, $table_param_is_class_name ) = @_;
    my $result_set;
    if ($table_param_is_class_name) {
        $result_set = $schema->resultset($table);
    }
    else {
        my $src = DBIxHelper->get_result_class( $schema, $table );
        $result_set = $schema->resultset( $src->result_class );
    }

    bless $result_set, 'DBIx::Table::TestDataGenerator::ResultSetWithRandom';
    my %result;

    my $row = $result_set->rand->single;

    #TODO: extract data, put into %result
    foreach ( @{$colname_list} ) {
        $result{$_} = ${ $row->{_column_data} }{$_};
    }
    return \%result;
}

1;    # End of DBIx::Table::TestDataGenerator::Randomize

__END__

=pod

=head1 NAME

DBIx::Table::TestDataGenerator::Randomize - random record selections

=head1 DESCRIPTION

Handles random selection of column values in a DBIx::Class context.

=head1 SUBROUTINES/METHODS

=head2 random_record

Arguments:

=over 4

=item * schema: DBIx schema of the target database

=item * table: Name of a table or name of the corresponding DBIx ResultSource.

=item * colname_list: Reference to an array containing the column names for which values are to be selected randomly.

=item * table_param_is_class_name: If true, the table argument contains the DBIx class name, otherwise the original name of the target table.

=back

Returns a hash where the keys are the column names passed in in the argument colname_list and the corresponding values come from a randomly selected record of the target table.

=head1 AUTHOR

Jose Diaz Seng, C<< <josediazseng at gmx.de> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012-2013, Jose Diaz Seng.

This module is free software; you can redistribute it and/or modify it under the same terms as Perl 5.10.0. For more details, see the full text of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but without any warranty; without even the implied warranty of merchantability or fitness for a particular purpose. 
