package Alien::Role::Dino::linux;

use strict;
use warnings;
use 5.008001;
use Role::Tiny;

requires 'libs';
requires 'rpath';

around libs => sub {
  my($orig, $self) = @_;
  join(' ', (map { "-Wl,-rpath,$_" } $self->rpath), $orig->($self));
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::Role::Dino::linux

=head1 VERSION

version 0.07

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
