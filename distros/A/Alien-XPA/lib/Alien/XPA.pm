package Alien::XPA;

# ABSTRACT: Find or Build libxpa

use v5.10;
use strict;
use warnings;

our $VERSION = 'v2.1.20.4';

use base qw( Alien::Base );

1;

#
# This file is part of Alien-XPA
#
# This software is Copyright (c) 2017 by Smithsonian Astrophysical Observatory.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

__END__

=pod

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory metacpan

=head1 NAME

Alien::XPA - Find or Build libxpa

=head1 VERSION

version v2.1.20.4

=head1 DESCRIPTION

This distribution installs the XPA library if its not available. It
provides a uniform interface via L<Alien::Base> to configuration
information useful to link against it.

This module finds or builds version 2.1.20 of the C<XPA> library,
which is bundled.

C<XPA> is distributed under the MIT License.

For more information, please see L<Alien::Build::Manual::AlienUser>

=head1 USAGE

Please see L<Alien::Build::Manual::AlienUser> (or equivalently on
metacpan
L<https://metacpan.org/pod/distribution/Alien-Build/lib/Alien/Build/Manua
l/AlienUser.pod>).

=head1 SUPPORT

=head2 Bugs

Please report any bugs or feature requests to bug-alien-xpa@rt.cpan.org  or through the web interface at: L<https://rt.cpan.org/Public/Dist/Display.html?Name=Alien-XPA>

=head2 Source

Source is available at

  https://gitlab.com/djerius/alien-xpa

and may be cloned from

  https://gitlab.com/djerius/alien-xpa.git

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
