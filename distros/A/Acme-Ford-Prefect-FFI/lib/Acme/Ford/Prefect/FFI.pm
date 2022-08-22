package Acme::Ford::Prefect::FFI;

use strict;
use warnings;
use 5.008001;
use Acme::Alien::DontPanic ();
use FFI::Platypus::Declare;

# ABSTRACT: FFI test module for Alien::Base
our $VERSION = '2.5900'; # VERSION


our($dll) = Acme::Alien::DontPanic->dynamic_libs;
die "no dll found for libdontpanic" unless $dll;
lib $dll;

attach answer => [] => int => '';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::Ford::Prefect::FFI - FFI test module for Alien::Base

=head1 VERSION

version 2.5900

=head1 SYNOPSIS

 use Acme::Ford::Prefect::FFI;
 
 my $answer = Acme::Ford::Prefect::FFI::answer(); # == 42 of course

=head1 DESCRIPTION

L<Alien::Base> comprises base classes to help in the construction of C<Alien::> modules.  Modules in the L<Alien> namespace are used to locate and install (if necessary)
external libraries needed by other Perl modules.

This module is a toy module to test the efficacy of the L<Alien::Base> system with its experimental FFI interfaces.  This module depends on another toy module 
L<Acme::Alien::DontPanic> which provides the needed libdontpanic library to be able to tell us the C<answer> to life, the universe and everything.

=head1 FUNCTIONS

=head2 answer

 my $answer = Acme::Ford::Prefect::FFI::answer();

Returns the answer to life the universe and everything.  Not exported.

=head1 SEE ALSO

=over 4

=item L<FFI::Platypus>

=item L<Alien::Base>

=item L<Alien>

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014-2022 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
