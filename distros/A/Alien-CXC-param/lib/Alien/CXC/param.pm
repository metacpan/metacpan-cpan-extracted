package Alien::CXC::param;

# ABSTRACT: Build and Install the CIAO cxcparam library

use v5.12;
use strict;
use warnings;

our $VERSION = '0.04';

use base qw( Alien::Base );

1;

#
# This file is part of Alien-CXC-param
#
# This software is Copyright (c) 2023 by Smithsonian Astrophysical Observatory.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

__END__

=pod

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory metacpan cxcparam

=head1 NAME

Alien::CXC::param - Build and Install the CIAO cxcparam library

=head1 VERSION

version 0.04

=head1 SYNOPSIS

  use Alien::CXC::param;

=head1 DESCRIPTION

This module finds or builds the I<cxcparam> library extracted from
the Chandra Interactive Analysis of Observations (CIAO) software
package produced by the Chandra X-Ray Center (CXC).
See L<https://cxc.harvard.edu/ciao/> for more information.

The C<cxcparam> library is itself released under separate license.
See the README file in the included distribution tarball.

=head1 USAGE

Please see L<Alien::Build::Manual::AlienUser> (or equivalently on L<metacpan|https://metacpan.org/pod/distribution/Alien-Build/lib/Alien/Build/Manual/AlienUser.pod>).

=head1 SUPPORT

=head2 Bugs

Please report any bugs or feature requests to bug-alien-cxc-param@rt.cpan.org  or through the web interface at: L<https://rt.cpan.org/Public/Dist/Display.html?Name=Alien-CXC-param>

=head2 Source

Source is available at

  https://gitlab.com/djerius/alien-cxc-param

and may be cloned from

  https://gitlab.com/djerius/alien-cxc-param.git

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2023 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
