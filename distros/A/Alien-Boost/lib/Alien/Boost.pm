package Alien::Boost;

use strict;
use warnings;
use base qw( Alien::Base );

our $VERSION = '1.1';

=head1 NAME

Alien::Boost - Wrapper for installing Boost

=head1 DESCRIPTION

Alien::Boost is a wrapper to install Boost library. Modules
that depend on Boost can depend on Alien::Boost and use the
CPAN shell to install it for you.

Win32 is currently not supported, please help supporting it if
you're interested.

=head1 AUTHOR

Thibault Duponchelle E<lt>thibault.duponchelle@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2020 by Thibault Duponchelle

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=over 4

=item * L<Alien>

=back

=head1 REPOSITORY

L<https://github.com/thibaultduponchelle/Alien-Boost>

=cut

1;
