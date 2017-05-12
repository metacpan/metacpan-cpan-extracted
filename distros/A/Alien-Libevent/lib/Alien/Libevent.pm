package Alien::Libevent;

use strict;
use warnings;

our $VERSION = '0.01004';

=head1 NAME

Alien::Libevent - Wrapper for installing libevent v1.4.13

=head1 DESCRIPTION

Alien::Libevent is a wrapper to install libevent library. Modules
that depend on libevent can depend on Alien::Libevent and use the
CPAN shell to install it for you.

Win32 is currently not supported, please help supporting it if
you're interested.

=head1 AUTHOR

Johannes Plunien E<lt>plu@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 by Johannes Plunien

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=over 4

=item * L<Alien>

=back

=head1 REPOSITORY

L<http://github.com/plu/alien-libevent/>

=cut

1;
