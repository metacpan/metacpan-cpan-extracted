package DBIx::Table::TestDataGenerator::DataType;
use Moo;

use strict;
use warnings;

our $VERSION = "0.005";
$VERSION = eval $VERSION;

use Carp;

sub is_text {
    my ( $self, $col_type ) = @_;
    return $col_type !~ /\b(?:integer|number|numeric|decimal|long)\b/i;
}

1;    # End of DBIx::Table::TestDataGenerator::DataType

__END__

=pod

=head1 NAME

DBIx::Table::TestDataGenerator::DataType - handles SQL data types

=head1 DESCRIPTION

Collects methods used internally to handle the diverse SQL data types.

=head1 SUBROUTINES/METHODS

=head2 is_text

Argument: The DBIx::Class::ResultSource column_info method returns a hash describing a particular "table" column. is_text expects one of the possible values corresponding to the key "data_type" of such a hash.

The method returns a truish value if the passed in column type name is a string data type.

=head1 AUTHOR

Jose Diaz Seng, C<< <josediazseng at gmx.de> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012-2013, Jose Diaz Seng.

This module is free software; you can redistribute it and/or modify it under the same terms as Perl 5.10.0. For more details, see the full text of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but without any warranty; without even the implied warranty of merchantability or fitness for a particular purpose.
