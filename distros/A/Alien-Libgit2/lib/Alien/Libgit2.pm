# ABSTRACT: Find or build libgit2, the linkable Git library

package Alien::Libgit2;
our $VERSION = '0.001';
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

version 0.001

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

It first checks whether a system C<libgit2> (>= 1.5) is available via
C<pkg-config>. If not, it builds libgit2 from a bundled source tarball
using CMake. No network access is required during install.

=head1 SEE ALSO

L<Git::Libgit2>, L<Git::Native>, L<Alien::Build>, L<Alien::Base>

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
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
