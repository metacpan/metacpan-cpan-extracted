package Algorithm::EventsPerSecond::XS;

use 5.006;
use strict;
use warnings;

=head1 NAME

Algorithm::EventsPerSecond::XS - XS accelerated backend for Algorithm::EventsPerSecond

=head1 DESCRIPTION

Do not use this module directly. L<Algorithm::EventsPerSecond> loads it
automatically when it is usable and falls back to pure Perl when it is not.

The bucket counts and their timestamps are kept in packed C<int64_t>
buffers (Perl strings), so the window scan in C<_xs_count> runs over
contiguous memory. When compiled on a machine with AVX2 or SSE4.2 an
explicit SIMD path is used; otherwise a branchless scalar loop is
emitted that compilers readily auto-vectorize at C<-O3>.

The XS is compiled when C<perl Makefile.PL && make> runs, so the
environment variables below take effect at install time:

=over 4

=item IF_OPT

The C<-O> optimization value. C<IF_OPT=2> (or C<IF_OPT=-O2>) compiles
with C<-O2>. Defaults to C<-O3>.

=item IF_ARCH

The target architecture. C<IF_ARCH=native> (or C<IF_ARCH=-march=native>)
compiles with C<-march=native>, unlocking whatever SIMD the build host
supports. Unset by default, leaving the compiler's baseline.

=back

Passing C<PUREPERL_ONLY=1> to C<Makefile.PL> skips building the XS
entirely, as does lacking a working C compiler; in either case
L<Algorithm::EventsPerSecond> uses its pure Perl implementation.

=cut

our $VERSION = '0.0.1';

require XSLoader;
XSLoader::load( 'Algorithm::EventsPerSecond::XS', $VERSION );

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by Zane C. Bowers-Hadley.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut

1; # End of Algorithm::EventsPerSecond::XS
