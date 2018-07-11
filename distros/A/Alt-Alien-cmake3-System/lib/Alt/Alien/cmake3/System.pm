package Alt::Alien::cmake3::System;

use strict;
use warnings;
use 5.008001;

# ABSTRACT: Simplified alternative to Alien::cmake3 that uses system cmake
our $VERSION = '0.0402'; # VERSION


sub can_run
{
  require IPC::Cmd;
  !!IPC::Cmd::can_run('cmake');
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alt::Alien::cmake3::System - Simplified alternative to Alien::cmake3 that uses system cmake

=head1 VERSION

version 0.0402

=head1 SYNOPSIS

 env PERL_ALT_INSTALL=OVERWRITE cpanm -n Alt::Alien::cmake3::System

=head1 DESCRIPTION

This distribution provides an alternative implementation of Alien::cmake3 that only works with a 
system cmake.  It is intended for testing the core of L<Alien::Build>, which includes optional 
tests that use L<Alien::cmake3>.  The problem with using the real L<Alien::cmake3> for testing the 
core of L<Alien::Build> in CI is that L<Alien::cmake3> also depends on L<Alien::Build>.  This module
may also be useful for system integrators, although I discourage it for that use, as this module may
not be as well supported as the real L<Alien::cmake3>.

=head1 CAVEATS

The tests use L<Test::Alien> which is now part of the same distribution as L<Alien::Build>, so you 
have the same chicken and egg problem.  It is recommended to use the C<-n> option on cpanm to skip 
the testing phase.

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
