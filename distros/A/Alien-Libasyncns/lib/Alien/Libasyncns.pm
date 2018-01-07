package Alien::Libasyncns;
use strict;
use warnings;
use parent 'Alien::Base';

our $VERSION = '0.002';

1;
__END__

=encoding utf-8

=head1 NAME

Alien::Libasyncns - Alien package for libasyncns

=head1 SYNOPSIS

  use Alien::Libasyncns;

=head1 DESCRIPTION

Alien::Libasyncns is an Alien package for L<libasyncns|http://0pointer.de/lennart/projects/libasyncns/>.

=head1 HINTS

=over 4

=item How do I install Net::LibAsyncNS linking Alien::Libasyncns?

First install Alien::Libasyncns:

  cpanm -nq Alien::Libasyncns

Then install Net::LibAsyncNS with PKG_CONFIG_PATH set:

  export PKG_CONFIG_PATH=`perl -MAlien::Libasyncns -e 'print Alien::Libasyncns->dist_dir'`/lib/pkgconfig
  cpanm -nq Net::LibAsyncNS

=back

=head1 SEE ALSO

L<http://0pointer.de/lennart/projects/libasyncns/>

=head1 AUTHOR

Shoichi Kaji <skaji@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2017 Shoichi Kaji <skaji@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

The license of libasyncns is:

  This program is free software; you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as published by the Free Software Foundation, either version 2.1 of the License, or (at your option) any later version.

  This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more details.

=cut
