package Acme::Alien::DontPanic2;

use strict;
use warnings;
use base 'Alien::Base';

# ABSTRACT: Test Module for Alien::Base + Alien::Build
our $VERSION = '0.3200'; # VERSION


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::Alien::DontPanic2 - Test Module for Alien::Base + Alien::Build

=head1 VERSION

version 0.3200

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

L<http://github.com/Perl5-Alien/Acme-Alien-DontPanic2>

=head1 AUTHORS

=over 4

=item *

Graham Ollis <plicease@cpan.org>

=item *

Joel A Berger <joel.a.berger@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Joel A Berger.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
