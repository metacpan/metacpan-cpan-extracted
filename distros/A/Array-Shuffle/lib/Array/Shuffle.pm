package Array::Shuffle;

our $VERSION = '0.03';

use strict;
use warnings;

require XSLoader;
XSLoader::load('Array::Shuffle', $VERSION);

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(shuffle_array shuffle_huge_array);

1;
__END__

=head1 NAME

Array::Shuffle - fast shuffling of arrays in-place

=head1 SYNOPSIS

  use Array::Shuffle qw(shuffle_array);
  shuffle_array(@a);

=head1 DESCRIPTION

This module provide some functions for shuffling arrays in-place
efficiently.

=head2 API

=over 4

=item shuffle_array @a

Shuffles the given array in-place using the Fisher-Yates algorithm that
is O(N).

This function is an order of magnitude faster than the shuffle
function from L<List::Util>.

=item shuffle_huge_array @a

Shuffles the given array in-place using an algorithm that is O(NlogN)
but more cache friendly than Fisher-Yates. In some extreme cases, when
shuffling huge arrays that do not find in the available RAM it may
perform better.

You would like to do some benchmarking to find out which one is better
suited for your particular case.

=back

=head1 SEE ALSO

L<List::Util>.

The following thread on PerlMonks for a discussion on the topic:
L<http://perlmonks.org/?node_id=953607>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Salvador FandiE<ntilde>o (sfandino@yahoo.com)

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

=cut
