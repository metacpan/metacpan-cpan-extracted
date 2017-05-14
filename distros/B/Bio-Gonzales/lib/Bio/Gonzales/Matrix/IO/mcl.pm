#Copyright (c) 2010 Joachim Bargsten <code at bargsten dot org>. All rights reserved.

package Bio::Matrix::IO::mcl;

use Mouse;

use MouseX::Foreign 'Bio::Matrix::IO';

use warnings;
use strict;

use 5.010;
our $VERSION = '0.0546'; # VERSION

with 'Bio::Gonzales::Role::BioPerl::Constructor';

sub next_matrix {
    confess 'not implemented';
}

sub write_matrix {
    my ( $self, @matricies ) = @_;
    foreach my $matrix (@matricies) {

        my @rows = $matrix->row_names;
        my @cols = $matrix->column_names;

        my $str;
        for ( my $i = 0; $i < @rows; $i++ ) {
            my @row = $matrix->get_row( $rows[$i] );
            for ( my $j = 0; $j < $i; $j++ ) {
                $str .= "$rows[$i] $cols[$j] $row[$j]\n";
            }
        }
        $self->_print($str);
    }

}

1;
