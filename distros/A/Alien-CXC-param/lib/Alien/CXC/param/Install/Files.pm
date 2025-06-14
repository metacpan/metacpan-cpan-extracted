package Alien::CXC::param::Install::Files;

use v5.10;
use strict;
use warnings;

our $VERSION = '0.04';

require Alien::CXC::param;

sub Inline { shift; Alien::CXC::param->Inline( @_ ) }
1;

__END__

=pod

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory

=head1 NAME

Alien::CXC::param::Install::Files

=head1 VERSION

version 0.04

=for Pod::Coverage   Inline

=head1 SUPPORT

=head2 Bugs

Please report any bugs or feature requests to bug-alien-cxc-param@rt.cpan.org  or through the web interface at: L<https://rt.cpan.org/Public/Dist/Display.html?Name=Alien-CXC-param>

=head2 Source

Source is available at

  https://gitlab.com/djerius/alien-cxc-param

and may be cloned from

  https://gitlab.com/djerius/alien-cxc-param.git

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Alien::CXC::param|Alien::CXC::param>

=back

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2023 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
