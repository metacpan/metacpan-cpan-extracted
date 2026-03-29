# ABSTRACT: Find or build libssh, the SSH library

package Alien::libssh;
our $VERSION = '0.001';
use strict;
use warnings;
use parent 'Alien::Base';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::libssh - Find or build libssh, the SSH library

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  use Alien::libssh;

  # cflags and libs are available via Alien::Base methods
  my $cflags = Alien::libssh->cflags;
  my $libs   = Alien::libssh->libs;

=head1 DESCRIPTION

L<Alien::libssh> provides the C library L<libssh|https://www.libssh.org/>
for use by other CPAN modules that need to link against it.

It first checks whether a system C<libssh> is available via C<pkg-config>.
If not, it downloads and builds libssh from source using CMake.

=head1 SEE ALSO

L<Net::LibSSH>, L<Alien::Build>, L<Alien::Base>

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-alien-libssh/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
