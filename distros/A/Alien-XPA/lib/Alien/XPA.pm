package Alien::XPA;

# ABSTRACT: Find or Build libxpa

use strict;
use warnings;

our $VERSION = '0.09';

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

=pod

=head1 NAME

Alien::XPA - Find or Build libxpa

=head1 VERSION

version 0.09

=head1 DESCRIPTION

This distribution installs the XPA library if its not available. It
provides a uniform interface via L<Alien::Base> to configuration
information useful to link against it.

For more information, please see L<Alien::Build::Manual::AlienUser>

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<https://rt.cpan.org/Public/Dist/Display.html?Name=Alien-XPA>.

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut

__END__

#pod =head1 DESCRIPTION
#pod
#pod This distribution installs the XPA library if its not available. It
#pod provides a uniform interface via L<Alien::Base> to configuration
#pod information useful to link against it.
#pod
#pod For more information, please see L<Alien::Build::Manual::AlienUser>
#pod
