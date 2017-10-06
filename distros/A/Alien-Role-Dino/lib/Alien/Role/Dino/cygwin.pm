package Alien::Role::Dino::cygwin;

use strict;
use warnings;
use 5.008001;
use Role::Tiny;
use Env qw( @PATH );

requires 'xs_load';
requires 'rpath';

around xs_load => sub {
  my($orig, $self, $package, $version, @rest) = @_;
  local $ENV{PATH} = $ENV{PATH};
  unshift @PATH, $self->rpath(@rest);
  $orig->($self, $package, $version, @rest);
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::Role::Dino::cygwin

=head1 VERSION

version 0.06

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
