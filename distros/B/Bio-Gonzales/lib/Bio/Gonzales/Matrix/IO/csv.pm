#Copyright (c) 2010 Joachim Bargsten <code at bargsten dot org>. All rights reserved.

package Bio::Gonzales::Matrix::IO::csv;

use Mouse;

use MouseX::Foreign 'Bio::Matrix::IO';

use List::MoreUtils qw/any/;
use Data::Dumper;

use warnings;
use strict;

use 5.010;
our $VERSION = '0.0546'; # VERSION

with 'Bio::Gonzales::Role::BioPerl::Constructor';

has 'na_value' => (is => 'rw', required => 1);

sub next_matrix {
    confess 'not implemented';
}

sub write_matrix {
    my ( $self, @matricies ) = @_;
    foreach my $matrix (@matricies) {

        my @row_names = $matrix->row_names;
        my @col_names = $matrix->column_names;

        my $str = join( "\t", @col_names );
        $str .= "\n";
        for ( my $i = 0; $i < @row_names; $i++ ) {
            my @row = $matrix->get_row( $row_names[$i] );
            @row = map { $_ < 0 ? $self->na_value : $_ } @row;
            $str .= join "\t", ( $row_names[$i], @row );
            $str .= "\n";
        }
        $self->_print($str);
    }
}

1;

