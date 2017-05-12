package Data::Transpose::Iterator::Errors;

use strict;
use warnings;

use Moo;

extends 'Data::Transpose::Iterator::Base';

=head1 NAME

Data::Transpose::Iterator::Errors - Iterator for validation errors.

The errors iterator provides C<errors_hash> method to retrieve
a structure suitable to show error message beside form fields.

=head1 METHODS

=head2 append

Appends record to iterator.

=cut

sub append {
    my ($self, $record) = @_;

    $self->records([@{$self->records}, $record]);
}

=head2 errors_hash

Returns records of the iterator as hash.
The value from "field" key is used as hash key and
the value from "errors" key is used as hash value.

=cut

sub errors_hash {
    my ( $self ) = @_;
    my ( %hash );

    for my $record ( @{$self->records} ) {
        unless (exists $record->{field}) {
            die "Missing entry for field in record.";
        }
        unless (exists $record->{errors}) {
            die "Missing entry for errors in record.";
        }

        $hash{$record->{field}} = [map {{name => $_->[0],
                                             value => $_->[1]}}
                                       @{$record->{errors}}];
    }

    return \%hash;
}

=head1 AUTHOR

Stefan Hornburg (Racke), <racke@linuxia.de>

=head1 LICENSE AND COPYRIGHT

Copyright 2014-2016 Stefan Hornburg (Racke) <racke@linuxia.de>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;

