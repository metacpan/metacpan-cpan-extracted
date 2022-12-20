package Alien::Gearman;

use strict;
use warnings;
use base qw( Alien::Base );

our $VERSION = '2.4';

=head1 NAME

Alien::Gearman - Wrapper for installing libgearman

=head1 DESCRIPTION

Alien::Gearman is a wrapper to install libgearman library. Modules
that depend on libgearman can depend on Alien::Gearman and use the
CPAN shell to install it for you.

Win32 is currently not supported, please help supporting it if
you're interested.

=head1 AUTHOR

Thibault Duponchelle E<lt>thibault.duponchelle@gmail.comE<gt>

Johannes Plunien E<lt>plu@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 by Thibault Duponchelle

Copyright 2009 by Johannes Plunien

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=over 4

=item * L<Alien>

=item * L<Gearman::XS>

=item * L<http://www.gearman.org/>

=back

=head1 REPOSITORY

L<https://github.com/thibaultduponchelle/Alien-Gearman>

=cut

1;
