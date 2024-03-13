package Alien::CFITSIO;

# ABSTRACT: Build and Install the CFITSIO library

use strict;
use warnings;

use base qw( Alien::Base );

our $VERSION = 'v4.4.0.2';
use constant
  CFITSIO_VERSION => 4.04;

  1;

#
# This file is part of Alien-CFITSIO
#
# This software is Copyright (c) 2022 by Smithsonian Astrophysical Observatory.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

__END__

=pod

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory metacpan

=head1 NAME

Alien::CFITSIO - Build and Install the CFITSIO library

=head1 VERSION

version v4.4.0.2

=head1 SYNOPSIS

  use Alien::CFITSIO;

=head1 DESCRIPTION

This module finds or builds the L<CFITSIO|https://heasarc.gsfc.nasa.gov/docs/software/fitsio/fitsio.html> library.  It supports CFITSIO
version 4.4.0.

=head1 USAGE

Please see L<Alien::Build::Manual::AlienUser> (or equivalently on L<metacpan|https://metacpan.org/pod/distribution/Alien-Build/lib/Alien/Build/Manual/AlienUser.pod>).

=head1 INSTALLATION

The environment variables C<ALIEN_CFITSIO_EXACT_VERSION> and
C<ALIEN_CFITSIO_ATLEAST_VERSION> may be used during installation to
install a specific version of CFITSIO or any version greater or equal
to a specific version.

By default, B<Alien::CFITSIO> will install CFITSIO version 4.4.0.

=head1 SUPPORT

=head2 Bugs

Please report any bugs or feature requests to bug-alien-cfitsio@rt.cpan.org  or through the web interface at: https://rt.cpan.org/Public/Dist/Display.html?Name=Alien-CFITSIO

=head2 Source

Source is available at

  https://gitlab.com/djerius/alien-cfitsio

and may be cloned from

  https://gitlab.com/djerius/alien-cfitsio.git

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
