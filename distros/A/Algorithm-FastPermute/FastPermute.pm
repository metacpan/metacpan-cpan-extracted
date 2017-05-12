package Algorithm::FastPermute;

use strict;
BEGIN {
    eval {require warnings};
    warnings->import if !$@
}

require 5.006;
require Exporter;
require DynaLoader;

use vars qw(@ISA @EXPORT $VERSION);

@ISA = qw(Exporter DynaLoader);
@EXPORT = qw(permute);
$VERSION = '0.999';

bootstrap Algorithm::FastPermute $VERSION;

1;
__END__

=head1 NAME

Algorithm::FastPermute - Rapid generation of permutations

=head1 SYNOPSIS

  use Algorithm::FastPermute ('permute');
  my @array = (1..shift());
  permute {
      print "@array\n";		# Print all the permutations
  } @array;

=head1 DESCRIPTION

Algorithm::FastPermute generates all the permutations of an array. You pass a
block of code, which will be executed for each permutation. The array will be
changed in place, and then changed back again before C<permute> returns. During
the execution of the callback, the array is read-only and you'll get an error
if you try to change its length. (You I<can> change its elements, but the
consequences are liable to confuse you and may change in future versions.)

You have to pass an array, it can't just be a list. It B<does> work with
special arrays and tied arrays, though unless you're doing something
particularly abstruse you'd be better off copying the elements into a normal
array first.

It's very fast. My tests suggest it's four or five times as fast as
Algorithm::Permute's traditional interface.  If you're permuting a large list
(nine or more elements, say) then you'll appreciate this enormously. If your
lists are short then Algorithm::Permute will still finish faster than you can
blink, and you may find its interface more convenient.

In fact, the FastPermute interface (and code) is now also included in
Algorithm::Permute, so you may not need both. Enhancements and bug fixes
will appear here first, from where (at Edwin Pratomo's discretion) they'll
probably make their way into Algorithm::Permute.

The code is run inside a pseudo block, rather than as a normal subroutine. That
means you can't use C<return>, and you can't jump out of it using C<goto> and
so on. Also, C<caller> won't tell you anything helpful from inside the
callback. Such is the price of speed.

The order in which the permutations are generated is not guaranteed, so don't
rely on it.

=head1 EXPORT

The C<permute> function is exported by default.

=head1 AUTHOR

Robin Houston, <robin@kitsite.com>

Based on a C program by Matt Day.

=head1 SEE ALSO

L<Algorithm::Permute>

=head1 COPYRIGHT

Copyright (c) 2001-2008, Robin Houston. All Rights Reserved.
This module is free software. It may be used, redistributed
and/or modified under the same terms as Perl itself.

=cut
