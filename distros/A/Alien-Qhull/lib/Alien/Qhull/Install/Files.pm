package Alien::Qhull::Install::Files;

use v5.12;
use strict;
use warnings;

our $VERSION = 'v8.0.2.2';

require Alien::Qhull;

sub Inline { shift; Alien::Qhull->Inline( @_ ) }
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

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory

=head1 NAME

Alien::Qhull::Install::Files

=head1 VERSION

version v8.0.2.2

=for Pod::Coverage Inline

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

L<Alien::Qhull|Alien::Qhull>

=back

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
