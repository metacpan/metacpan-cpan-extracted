package Alien::Qhull;

# ABSTRACT: Build and Install the Qhull library

use v5.12;
use strict;
use warnings;

our $VERSION = 'v8.0.2.1';

use base qw( Alien::Base );

1;

#
# This file is part of Alien-Qhull
#
# This software is Copyright (c) 2024 by Smithsonian Astrophysical Observatory.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

__END__

=pod

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory metacpan

=head1 NAME

Alien::Qhull - Build and Install the Qhull library

=head1 VERSION

version v8.0.2.1

=head1 SYNOPSIS

  use Alien::Qhull;

=head1 DESCRIPTION

This module finds or builds the I<Qhull> library and executables.

It requires Qhull version '8.0.2'.  If that is available
on the system, that is used, otherwise it will build a "share" version
using that version, which is distributed with this package.

=head2 Bundled executables

Qhull provides the following executables:

 qconvex  qdelaunay  qhalf  qhull  qvoronoi  rbox

The L<Alien::Qhull->bin_dir> will return a valid path if these are
available in a "system" install; they are always available in a
"share" install.

=head1 USAGE

Please see L<Alien::Build::Manual::AlienUser> (or equivalently on L<metacpan|https://metacpan.org/pod/distribution/Alien-Build/lib/Alien/Build/Manual/AlienUser.pod>).

=head1 SUPPORT

=head2 Bugs

Please report any bugs or feature requests to bug-alien-qhull@rt.cpan.org  or through the web interface at: L<https://rt.cpan.org/Public/Dist/Display.html?Name=Alien-Qhull>

=head2 Source

Source is available at

  https://gitlab.com/djerius/alien-qhull

and may be cloned from

  https://gitlab.com/djerius/alien-qhull.git

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<www.qhull.org>

=back

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
