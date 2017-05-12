package BERT::Constants;
use strict;
use warnings;

use 5.008;

use base 'Exporter';

# BERT encoding only supports data type identifiers 97-100 and 104-111
use constant {
    SMALL_INTEGER_EXT => 97,
    INTEGER_EXT       => 98,
    FLOAT_EXT         => 99,
    ATOM_EXT          => 100,
    SMALL_TUPLE_EXT   => 104,
    LARGE_TUPLE_EXT   => 105,
    NIL_EXT           => 106,
    STRING_EXT        => 107,
    LIST_EXT          => 108,
    BINARY_EXT        => 109,
    SMALL_BIG_EXT     => 110,
    LARGE_BIG_EXT     => 111,

    MAGIC_NUMBER      => 131,
    
    ERL_MAX  => (1 << 27) - 1,
    ERL_MIN  => -(1 << 27),
};

our @EXPORT = qw(
    SMALL_INTEGER_EXT
    INTEGER_EXT
    FLOAT_EXT
    ATOM_EXT
    SMALL_TUPLE_EXT
    LARGE_TUPLE_EXT
    NIL_EXT
    STRING_EXT
    LIST_EXT
    BINARY_EXT
    SMALL_BIG_EXT
    LARGE_BIG_EXT

    MAGIC_NUMBER

    ERL_MAX
    ERL_MIN
);

1;

__END__

=head1 NAME

BERT::Constants - Various constants for BERT serialization

=head1 AUTHOR

Sherwin Daganato E<lt>sherwin@daganato.comE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<BERT>

=cut
