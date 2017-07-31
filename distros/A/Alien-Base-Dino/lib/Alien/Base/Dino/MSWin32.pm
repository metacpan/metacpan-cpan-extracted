package Alien::Base::Dino::MSWin32;

use strict;
use warnings;
use 5.008001;
use Env qw( @PATH );

sub Alien::Base::Dino::_xs_load_wrapper
{
  my($self, $code, @rest) = @_;
  local $ENV{PATH} = $ENV{PATH};
  unshift @PATH, $self->rpath(@rest);
  $code->();
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::Base::Dino::MSWin32

=head1 VERSION

version 0.01

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
