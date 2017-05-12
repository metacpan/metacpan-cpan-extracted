package Alien::GMP;

use v5.10;
use strict;
use warnings FATAL => "all";
use utf8;

our $VERSION = 'v0.0.6'; # VERSION
# ABSTRACT: Build and install the GNU Multiple Precision library.

sub inc_dir () { "##" }

sub lib_dir () { "##" }

1;
=encoding utf8

=head1 NAME

Alien::GMP - Build and install the GNU Multiple Precision library.

=head1 SYNOPSIS

	my $inc_dir = Alien::GMP::inc_dir();
	my $lib_dir = Alien::GMP::lib_dir();

=head1 DESCRIPTION

This module looks for version 5.0.0 or greater of the GNU Multiple Precision
(GMP) library. If not found, the builder script downloads, compiles, and
installs it to the B<Alien-GMP> distribution's shared directory. Compilation can
be made to happen regardless of whether GMP is already found by setting the
environment variable, C<COMPILE_ALIEN_GMP>, to a true value.

=head1 FUNCTIONS

=over

=item B<Alien::GMP::inc_dir()>

Takes no arguments and returns the C I<includes> directory that contains
C<gmp.h>.

=item B<Alien::GMP::lib_dir()>

Takes no arguments and returns the C I<libraries> directory that contains
C<libgmp.so>.

=back

=head1 AUTHOR

Richard Simões C<< <rsimoes AT cpan DOT org> >>

=head1 COPYRIGHT & LICENSE

Copyright © 2012 Richard Simões. This module is released under the terms of the
L<GNU Lesser General Public License|http://gnu.org/licenses/lgpl.html> ("LGPL")
v. 3.0 and may be modified and/or redistributed under the same or any compatible
license. The GNU Multiple Precision library itself is copyrighted by the
L<Free Software Foundation|http://www.fsf.org/> and is also distributed under
terms of the LGPL v. 3.0.
