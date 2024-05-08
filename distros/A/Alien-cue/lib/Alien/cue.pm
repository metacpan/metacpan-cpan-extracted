package Alien::cue;

use strict;
use warnings;
use 5.008004;
use base qw( Alien::Base );

# ABSTRACT: Find or download the cue configuration language tool
our $VERSION = '0.01'; # VERSION




sub alien_helper
{
  return {
    cue => sub { 'cue' },
  };
}





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::cue - Find or download the cue configuration language tool

=head1 VERSION

version 0.01

=head1 SYNOPSIS

In your script or module:

 use Alien::cue;
 use Env qw( @PATH );

 unshift @PATH, Alien::cue->bin_dir;

=head1 DESCRIPTION

This package can be used by other CPAN modules that require cue,
the configuration language tool.

=head1 HELPERS

=head2 cue

 %{cue}

Returns the name of the cue command.  Usually just C<cue>.

=head1 SEE ALSO

L<Alien>, L<Alien::Base>, L<Alien::Build::Manual::AlienUser>

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
