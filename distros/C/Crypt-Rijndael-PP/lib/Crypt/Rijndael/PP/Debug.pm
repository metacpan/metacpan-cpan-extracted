package Crypt::Rijndael::PP::Debug;

use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw( generate_printable_state );

our $VERSION = '0.3.0'; # VERSION
# ABSTRACT: Debugging and Formatting Methods

sub generate_printable_state {
    my $state = shift;

    my $state_as_string = "";

    for( my $row_index = 0; $row_index < 4; $row_index++ ) {
        for( my $column_index = 0; $column_index < 4; $column_index++ ) {
            my $state_byte = unpack("H2", $state->[$row_index][$column_index] );
            $state_as_string .= $state_byte . " ";
        }

        chop $state_as_string;
        $state_as_string .= "\n";
    }

    chop $state_as_string;

    return $state_as_string;
}

1;
