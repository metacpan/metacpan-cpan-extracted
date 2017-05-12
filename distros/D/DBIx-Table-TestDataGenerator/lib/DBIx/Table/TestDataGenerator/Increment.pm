package DBIx::Table::TestDataGenerator::Increment;
use Moo;

use strict;
use warnings;

our $VERSION = "0.005";
$VERSION = eval $VERSION;

use Carp;

use aliased 'DBIx::Table::TestDataGenerator::DataType';

sub get_incrementor {
    my ( $self, $type, $max ) = @_;
    if ( DataType->is_text($type) ) {
        my $i      = 0;
        my $suffix = 'A' x $max;
        return sub {
            return $suffix . $i++;
          }
    }

    return sub { return ++$max };
}

sub get_type_preference_for_incrementing {
    my @types =
      qw / DECIMAL DOUBLE FLOAT NUMBER NUMERIC REAL BIGINT INTEGER SMALLINT
      TINYINT NVARCHAR2 NVARCHAR LVARCHAR VARCHAR2 VARCHAR LONGCHAR NTEXT
      TEXT /;
    return \@types;
}

1;    # End of DBIx::Table::TestDataGenerator::Increment

__END__

=pod

=head1 NAME

DBIx::Table::TestDataGenerator::Increment - incrementing constrained columns

=head1 DESCRIPTION

Handles incrementing columns constrained by uniqueness conditions.

=head1 SUBROUTINES/METHODS

=head2 get_incrementor

Arguments:

=over 4

=item * type: a column data type of the current DBMS

=item * max: start value, to be successively incremented by the incrementor

=back

Returns an anonymous function for incrementing the values of a column of data type $type starting at a value to be determined by the current "maximum" $max. In case of a numeric data type, $max will be just the current maximum, but in case of strings, we have decided to pass the maximum length since there is no natural ordering available. E.g. Perl using per default another order than the lexicographic order employed by Oracle. In our default implementations, for string data types we add values for the current column at 'A...A0', where A is repeated $max times and increase the appended integer in each step. This should be made more flexible in future versions.

=head2 get_type_preference_for_incrementing

Arguments: none

We must decide which of the column values of a record to be added will be changed in case of a uniqueness constraint. This method returns a reference to an array listing the supported data types. The order of the data types defines which column in such a unique constraint will get preference over others based on its data type.

=head1 AUTHOR

Jose Diaz Seng, C<< <josediazseng at gmx.de> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012-2013, Jose Diaz Seng.

This module is free software; you can redistribute it and/or modify it under the same terms as Perl 5.10.0. For more details, see the full text of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but without any warranty; without even the implied warranty of merchantability or fitness for a particular purpose. 
