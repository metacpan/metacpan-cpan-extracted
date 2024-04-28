package Alien::NLOpt::Install::Files;

use v5.12;
use strict;
use warnings;

our $VERSION = 'v2.7.1.0';

require Alien::NLOpt;

sub Inline { shift; Alien::NLOpt->Inline( @_ ) }
1;

#
# This file is part of Alien-NLOpt
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

Alien::NLOpt::Install::Files

=head1 VERSION

version v2.7.1.0

=for Pod::Coverage Inline

=head1 SUPPORT

=head2 Bugs

Please report any bugs or feature requests to bug-alien-nlopt@rt.cpan.org  or through the web interface at: L<https://rt.cpan.org/Public/Dist/Display.html?Name=Alien-NLOpt>

=head2 Source

Source is available at

  https://gitlab.com/djerius/alien-nlopt

and may be cloned from

  https://gitlab.com/djerius/alien-nlopt.git

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Alien::NLOpt|Alien::NLOpt>

=back

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
