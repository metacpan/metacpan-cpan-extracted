package Alien::Base::Dino::gnukfreebsd;

use strict;
use warnings;
use 5.008001;

package Alien::Base::Dino;

sub libs
{
  my($self) = @_;
  join(' ', (map { "-Wl,-rpath,$_" } $self->rpath), $self->SUPER::libs);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::Base::Dino::gnukfreebsd

=head1 VERSION

version 0.01

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
