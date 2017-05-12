package Alt::Alien::FFI::System;

use strict;
use warnings;
use 5.008001;

# ABSTRACT: Simplified alternative to Alien::FFI that uses system libffi
our $VERSION = '0.16'; # VERSION


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alt::Alien::FFI::System - Simplified alternative to Alien::FFI that uses system libffi

=head1 VERSION

version 0.16

=head1 SYNOPSIS

 env PERL_ALT_INSTALL=OVERWRITE cpanm Alt::Alien::FFI::System

=head1 DESCRIPTION

This distribution provides an alternative implementation of
L<Alien::FFI> that is geared toward system integrators when
libffi is provided by the operating system.  It has no non-core
requirements for runtime as of Perl 5.8.  It now uses
use L<Test::Alien> for consistency with the original
L<Alien::FFI>.

It will NOT attempt to download or install libffi.  If you
need that, then install the original L<Alien::FFI> instead.

=head1 SEE ALSO

=over 4

=item L<Alt>

=item L<Alien::FFI>

=item L<FFI::Platypus>

=item L<FFI::Raw>

=item L<FFI::CheckLib>

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
