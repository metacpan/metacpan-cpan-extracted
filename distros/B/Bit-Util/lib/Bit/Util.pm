package Bit::Util;

our $VERSION = '0.02';

use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);

our @EXPORT_OK = qw(bu_first bu_last bu_count);

require XSLoader;
XSLoader::load('Bit::Util', $VERSION);

1;
__END__

=head1 NAME

Bit::Util - Utility subroutines for bit-vector manipulation

=head1 SYNOPSIS

  use Bit::Util qw(bu_count bu_last bu_first);

  my $vec = "foobardoz";

  my $cnt = bu_count($vec);
  my $first = bu_first($vec);
  my $last = bu_last($vec);

=head1 DESCRIPTION

This module provides some utility methods for bit-vector handling.

It is writting in XS and so its aim is to be very fast.

=head2 EXPORTABLE FUNCTIONS

=over 4

=item bu_count($vec [, $start [, $end]])

Counts the number of bits set in the bit-vector.

C<$start> and C<$end>, when given, allows to select a sub range of
bits inside the bit-vector. The bits at offsets bigger or equal than
C<$start> and smaller than C<$end> will be counted.

=item bu_first($vec [, $start])

Returns the index of the first bit set in the bit-vector.

If C<$start> is given it will start the search at the given index.

=item bu_last($vec [, $end])

Returns the index of the last bit set in the bit-vector.

If C<$end> is given it will start the search at the given index.

=back

=head1 SEE ALSO

L<perlfunc/vec>

=head1 AUTHOR

Salvador Fandino

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010, 2012 by Salvador Fandino, E<lt>sfandino@yahoo.comE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
