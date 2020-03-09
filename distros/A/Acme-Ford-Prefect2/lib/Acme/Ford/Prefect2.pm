package Acme::Ford::Prefect2;

use strict;
use warnings;

# ABSTRACT: Test Module for Alien::Base + Alien::Build
our $VERSION = '2.1100'; # VERSION

require DynaLoader;
our @ISA = 'DynaLoader';
__PACKAGE__->bootstrap($VERSION);
$VERSION = eval $VERSION;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::Ford::Prefect2 - Test Module for Alien::Base + Alien::Build

=head1 VERSION

version 2.1100

=head1 SYNOPSIS

 use Test2::V0;
 use Acme::Ford::Prefect2;

 is Acme::Ford::Prefect2::answer(), 42;
 # if 42 is returned then Acme::Alien::DontPanic2
 # properly provided the C library
 
 done_testing;

=head1 DESCRIPTION

L<Alien::Base> comprises base classes to help in the construction of C<Alien::> modules. Modules in the L<Alien> namespace are used to locate and install (if necessary) external libraries needed by other Perl modules.

This module is a toy module to test the efficacy of the L<Alien::Base> system. This module depends on another toy module L<Acme::Alien::DontPanic2>, which provides the needed the F<libdontpanic> library to be able to tell us the C<answer>.

=head1 FUNCTIONS

=head2 answer

Returns 42.

=head1 SEE ALSO

=over

=item * 

L<Alien::Base>

=item *

L<Alien>

=item *

L<Acme::Alien::DontPanic2>

=back

=head1 SOURCE REPOSITORY

L<http://github.com/Perl5-Alien/Acme-Ford-Prefect2>

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
