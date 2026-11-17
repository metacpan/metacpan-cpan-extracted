# ABSTRACT: Find or build libgit2, the linkable Git library

package Alien::Libgit2;
our $VERSION = '0.003';
use strict;
use warnings;
use parent 'Alien::Base';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::Libgit2 - Find or build libgit2, the linkable Git library

=head1 VERSION

version 0.003

=head1 SYNOPSIS

  use Alien::Libgit2;

  # For XS consumers
  my $cflags = Alien::Libgit2->cflags;
  my $libs   = Alien::Libgit2->libs;

  # For FFI consumers (FFI::Platypus, Git::Libgit2)
  my @libs = Alien::Libgit2->dynamic_libs;

=head1 DESCRIPTION

L<Alien::Libgit2> provides the C library L<libgit2|https://libgit2.org/>
for use by other CPAN modules that need to link against it.

It first checks whether a system C<libgit2> (>= 1.9.3) is available via
C<pkg-config>. If not, it builds libgit2 from a bundled source tarball
using CMake. No network access is required during install.

The 1.9.3 floor is a bug fix, not an API requirement: below it, libgit2's
ssh transport loops forever on C<LIBSSH2_ERROR_TIMEOUT>, so a peer that
accepts the connection and then goes silent parks the caller indefinitely.
A system lib below the fix falls through to the bundled share build.

=head1 INSTALLATION

  cpanm Alien::Libgit2

If C<pkg-config> reports a system libgit2 of 1.9.3 or newer, that one is
used. Otherwise the module builds from the bundled libgit2-1.9.3 tarball
using CMake. No network access is needed either way, so the install works
on air-gapped hosts.

=head2 Build dependencies (share install)

=over

=item * C<cmake>

=item * a C compiler

=item * C<pkg-config>

=item * OpenSSL headers (HTTPS backend)

=item * libssh2 headers (SSH transport)

=back

=head2 Forcing an install path

Set C<ALIEN_INSTALL_TYPE> before installing to skip the probe decision:
C<system> uses only a system libgit2 and fails if none meets the floor,
C<share> always builds the bundled tarball.

  ALIEN_INSTALL_TYPE=share cpanm Alien::Libgit2

=head1 USED BY

=over

=item * L<Git::Libgit2> - low-level FFI::Platypus bindings against libgit2

=item * L<Git::Native> - high-level Moo wrapper on top of L<Git::Libgit2>

=back

=head1 SEE ALSO

L<Git::Libgit2>, L<Git::Native>, L<Alien::Build>, L<Alien::Base>

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests at
L<https://github.com/Getty/p5-alien-libgit2/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
