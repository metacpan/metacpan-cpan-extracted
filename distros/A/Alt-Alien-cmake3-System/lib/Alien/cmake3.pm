package Alien::cmake3;

use strict;
use warnings;
use 5.008001;

# ABSTRACT: Find or download or build cmake 3 or better
our $VERSION = '0.0501'; # VERSION


sub cflags       { '' }
sub libs         { '' }
sub dynamic_libs { '' }
sub exe          { 'cmake' }

sub alien_helper
{
  return {
    cmake3 => 'cmake',
  };
}

sub bin_dir
{
  ();
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::cmake3 - Find or download or build cmake 3 or better

=head1 VERSION

version 0.0501

=head1 SYNOPSIS

See L<https://metacpan.org/pod/Alien::cmake3#SYNOPSIS>

=head1 DESCRIPTION

This is an L<Alt> version of L<Alien::cmake3>.  See the documentation for the real 
L<Alien::cmake3> here:

L<https://metacpan.org/pod/Alien::cmake3#DESCRIPTION>

See the documentation for the alternate implementation here:

L<Alt::Alien::cmake3::System>

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
