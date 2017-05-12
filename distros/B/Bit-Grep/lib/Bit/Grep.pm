package Bit::Grep;

our $VERSION = '0.01';

use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(bg_grep bg_sum bg_count_and_sum bg_count_sum_and_sum2 bg_avg);

require XSLoader;
XSLoader::load('Bit::Grep', $VERSION);

1;
__END__

=head1 NAME

Bit::Grep - select elements from an array using a bit vector

=head1 SYNOPSIS

  use Bit::Grep qw(bg_grep bg_sum);

  my @selected = bg_grep $vec, @array;
  my $sum = bg_sum $vec, @array

=head1 DESCRIPTION

This module provides some functions to select elements from and array
using a bit vector.

=head2 API

=over 4

=item @selected = bg_grep $vec, @array

Selects elements from @array using bit vector $vec as the selector.

It is equivalent to

  @selected = @array[grep vec($vec, $_, 1), 0..$#array];

=item $sum = bg_sum $vec, @array

Returns the sum of the elements of @array selected by $vec.

=item $sum = bg_avg $vec, @array

Returns the average of the elements of @array selected by $vec.

=item ($count, $sum) = bg_count_and_sum $vec, @array

Returns the number of elements selected and their sum

=item ($count, $sum, $sum2) = bg_count_and_sum $vec, @array

Returns the number of elements selected, their sum and the sum of
their squares.

=back

=head1 BUGS AND SUPPORT

If you find any bug on this module, please send a bug request through
the CPAN bug tracker
L<https://rt.cpan.org/Dist/Display.html?Queue=Language-Prolog-Yaswi>

Feedback or requests for new features are also welcome.

=head1 SEE ALSO

L<perlfunc/vec>, L<perlfunc/grep>, L<List::Util/sum>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Salvador FandiE<ntilde>o (sfandino@yahoo.com)

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10 or,
at your option, any later version of Perl 5 you may have available.

=cut
