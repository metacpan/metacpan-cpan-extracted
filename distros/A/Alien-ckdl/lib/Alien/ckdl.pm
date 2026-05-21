package Alien::ckdl;

use strict;
use warnings;
use parent 'Alien::Base';

our $VERSION = '0.001';

1;

__END__

=encoding utf-8

=head1 NAME

Alien::ckdl - Build and install ckdl, a C library for KDL documents

=head1 SYNOPSIS

In a consumer XS distribution's F<Makefile.PL>:

  use ExtUtils::MakeMaker;
  use Alien::Build::MM;

  my $abmm = Alien::Build::MM->new;

  WriteMakefile($abmm->mm_args(
      NAME      => 'Text::KDL::XS',
      PREREQ_PM => { 'Alien::ckdl' => 0 },
      CONFIGURE_REQUIRES => {
          'Alien::Build::MM' => '0.32',
          'Alien::ckdl'      => 0,
      },
  ));

  sub MY::postamble { $abmm->mm_postamble }

Or, to query the install paths directly:

  use Alien::ckdl;

  print Alien::ckdl->cflags, "\n";   # e.g. -I/.../include
  print Alien::ckdl->libs,   "\n";   # e.g. -L/.../lib -lkdl

=head1 DESCRIPTION

This distribution downloads, builds, and installs
L<ckdl|https://github.com/tjol/ckdl>, a C11 library for reading and
writing the KDL Document Language (KDL v1 and v2). It exposes the
result to Perl XS modules through the standard L<Alien::Base>
interface.

The Alien tracks the upstream C<main> branch rather than a tagged
release, and always installs from source as a B<static> library.
The upstream CMake build is intentionally bypassed: only the C source
files that make up C<libkdl> are compiled, omitting the upstream test
suite, the Python bindings, and the C++ bindings. As a result the
build has no Python, Cython, or CMake dependency.

The primary consumer is L<Text::KDL::XS>. End users who only want to
parse or emit KDL from Perl should install C<Text::KDL::XS> directly
and let it pull in this Alien as a build-time dependency.

=head1 METHODS

This class inherits from L<Alien::Base>; see that module for the full
list of methods. The ones most useful to a consumer are:

=over 4

=item C<< Alien::ckdl-E<gt>cflags >>

Compiler flags needed to find the bundled F<kdl/kdl.h> header. Returns
a string suitable for inclusion in a C compiler command line, for
example C<-I/path/to/share/include>.

=item C<< Alien::ckdl-E<gt>libs >>

Linker flags needed to statically link C<libkdl>. Returns a string
suitable for inclusion in a linker command line, for example
C<-L/path/to/share/lib -lkdl>.

=item C<< Alien::ckdl-E<gt>install_type >>

Always returns C<share>. This Alien does not detect or use a system
installation of C<ckdl>; it always builds from source into a private
share directory.

=back

When used through L<Alien::Build::MM>, the C<cflags> and C<libs>
strings are spliced into the generated Makefile automatically, so a
consumer's XS code can simply C<#include E<lt>kdl/kdl.hE<gt>> and link
against C<libkdl> with no extra configuration.

=head1 SEE ALSO

L<Text::KDL::XS>, the Perl XS binding that consumes this Alien.

L<Alien::Base> and L<Alien::Build>, the framework this distribution
plugs into.

L<https://github.com/tjol/ckdl>, the upstream C library.

L<https://github.com/kdl-org/kdl>, the KDL specification.

=head1 LICENSE

This Perl distribution is licensed under the same terms as Perl
itself.

The bundled C<ckdl> library is distributed under the MIT license. Its
C<COPYING> file is installed into the Alien share directory under
F<share/doc/ckdl/> for license compliance.

=cut
