package DBIx::Table::TestDataGenerator::DBIxHelper;
use Moo;

use strict;
use warnings;

our $VERSION = "0.005";
$VERSION = eval $VERSION;

use Carp;

{

    my %result_classes;

    sub get_result_class {
        my ( $self, $schema, $table ) = @_;

        $table = uc $table;

        return $result_classes{$table} if $result_classes{$table};

        foreach my $src_name ( $schema->sources ) {
            my $result_source = $schema->source($src_name);
            my %src_descr     = %{ $schema->source($src_name) };
            my $descr         = $src_descr{name};
            $descr = ref($descr) ? ${$descr} : $descr;
            $descr =~ s/^\W//;
            $descr =~ s/\W$//;
            next unless uc $descr eq $table;
            $result_classes{$table} = $result_source->result_class;
            return $result_classes{$table};
        }
        croak 'could not find result class for ' . $table
          unless $result_classes{$table};
        return;
    }

    sub column_names {
        my ( $self, $schema, $table ) = @_;
        my $cls = $self->get_result_class( $schema, $table );

        my @column_names = $cls->columns;
        return \@column_names;
    }

}

1;    # End of DBIx::Table::TestDataGenerator::DBIxHelper

__END__

=pod

=head1 NAME

DBIx::Table::TestDataGenerator::DBIxHelper - determines DBIx information and database metadata

=head1 DESCRIPTION

This class handles all purely DBIx related handling and the use of DBIx to determine metadata information about database objects.

=head1 SUBROUTINES/METHODS

=head2 get_result_class

Arguments: 

=over 4

=item * schema: DBIx schema of the target database

=item * table: Name of a table in the database the DBIx schema was created from.

=back

Returns the DBIx (short) name of the class corresponding to the database table.

=head2 column_names

Returns a reference to an array of the lower cased column names of the target table in no particular order.

=head1 AUTHOR

Jose Diaz Seng, C<< <josediazseng at gmx.de> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012-2013, Jose Diaz Seng.

This module is free software; you can redistribute it and/or modify it under the same terms as Perl 5.10.0. For more details, see the full text of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but without any warranty; without even the implied warranty of merchantability or fitness for a particular purpose. 
