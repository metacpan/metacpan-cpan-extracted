package Acme::Alien::DontPanic;

use strict;
use warnings;

our $VERSION = '0.042';

use parent 'Alien::Base';

1;

__END__

=head1 NAME

Acme::Alien::DontPanic - Test Module for Alien::Base

=head1 DESCRIPTION

L<Alien::Base> comprises base classes to help in the construction of C<Alien::> modules. Modules in the L<Alien> namespace are used to locate and install (if necessary) external libraries needed by other Perl modules.

This module is a toy module to test the efficacy of the L<Alien::Base> system. This module is depended on by another toy module L<Acme::Ford::Prefect>, which needs the F<libdontpanic> library to be able to tell us the C<answer>.

=head1 SEE ALSO

=over 

=item * 

L<Alien::Base>

=item *

L<Alien>

=item *

L<Acme::Ford::Prefect>

=back

=head1 SOURCE REPOSITORY

L<http://github.com/Perl5-Alien/Acme-Alien-DontPanic>

=head1 AUTHOR

Original author: Joel Berger, E<lt>joel.a.berger@gmail.comE<gt>

Current maintainer: Graham Ollis E<lt>plicease@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Joel Berger

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

