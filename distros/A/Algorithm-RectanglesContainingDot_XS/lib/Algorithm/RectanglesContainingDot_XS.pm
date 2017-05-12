package Algorithm::RectanglesContainingDot_XS;

use strict;
use warnings;

our $VERSION = '0.02';

require XSLoader;
XSLoader::load('Algorithm::RectanglesContainingDot_XS', $VERSION);

1;
__END__

=head1 NAME

Algorithm::RectanglesContainingDot_XS - C/XS implementation of Algorithm::RectanglesContainingDot

=head1 SYNOPSIS

  # install Algorithm::RectanglesContainingDot_XS and...
  use Algorithm::RectanglesContainingDot;

=head1 DESCRIPTION

This module implements the same algorithm as
L<Algorithm::RectanglesContainingDot> in C/XS and so it is much faster
(around 30 times faster!).

L<Algorithm::RectanglesContainingDot> will use this implementation
automatically when available.

=head1 SEE ALSO

L<Algorithm::RectanglesContainingDot>.

=head1 AUTHOR

Salvador FandiE<ntilde>o, E<lt>sfandino@yahoo.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2007 by Salvador Fandino.

Copyright (c) 2007 by Qindel Formacion y Servicios SL.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
