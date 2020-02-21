package Alien::LibCIAORegion;

# ABSTRACT: Find or build the CIAO Region library

use strict;
use warnings;

use base qw( Alien::Base );

our $VERSION = '0.01';

1;

#
# This file is part of Alien-LibCIAORegion
#
# This software is Copyright (c) 2020 by Smithsonian Astrophysical Observatory.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

__END__

=pod

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory cpan testmatrix url
annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata
placeholders metacpan CXC GPL

=head1 NAME

Alien::LibCIAORegion - Find or build the CIAO Region library

=head1 VERSION

version 0.01

=head1 SYNOPSIS

  use Alien::LibCIAORegion;

=head1 DESCRIPTION

This module finds or builds the I<region> library extracted from
the Chandra Interactive Analysis of Observations (CIAO) software
package produced by the Chandra X-Ray Center (CXC).
See L<https://cxc.harvard.edu/ciao/> for more information.

Unfortunately, there is no documentation accompanying the library.

The region library is itself released under the GPL, version 3.  See
the enclosed copyright information.

=head1 USAGE

Please see L<Alien::Build::Manual::AlienUser> (or equivalently on L<metacpan|https://metacpan.org/pod/distribution/Alien-Build/lib/Alien/Build/Manual/AlienUser.pod>).

=head1 SUPPORT

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/Alien-LibCIAORegion>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Alien-LibCIAORegion>

=back

=head2 Email

You can email the author of this module at C<DJERIUS at cpan.org> asking for help with any problems you have.

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-alien-libciaoregion at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=Alien-LibCIAORegion>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://gitlab.com/djerius/alien-libciaoregion>

  https://gitlab.com/djerius/alien-libciaoregion.git

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<CIAO::Lib::Region|CIAO::Lib::Region>

=back

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
