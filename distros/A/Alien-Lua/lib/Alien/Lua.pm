package Alien::Lua;
use 5.14.0;
use warnings;

our $VERSION = '5.2.2.2';
use parent 'Alien::Base';

our $CanUseLuaJIT;
BEGIN {
  $CanUseLuaJIT = 0;
  eval "require Alien::LuaJIT"
  and do {
    $CanUseLuaJIT = 1;
  };
}

sub new {
  my ($class, %opt) = @_;
  my $luajit = delete $opt{luajit};
  my $self = $class->SUPER::new(%opt);
  bless($self, __PACKAGE__);
  if ($luajit && $CanUseLuaJIT) {
    $self->{alien_luajit} = Alien::LuaJIT->new(%opt);
  }
  return $self;
}

sub luajit { return $_[0]->{alien_luajit} }

sub cflags {
  my $self = shift;
  if (not ref($self) or not $self->luajit) {
    return $self->SUPER::cflags(@_);
  }
  return $self->luajit->cflags(@_);
}

sub libs {
  my $self = shift;
  if (not ref($self) or not $self->luajit) {
    return $self->SUPER::libs(@_);
  }
  return $self->luajit->libs(@_);
}


1;
__END__

=head1 NAME

Alien::Lua - Alien module for asserting a liblua is available

=head1 SYNOPSIS

  use Alien::Lua;
  my $alien = Alien::Lua->new;
  my $libs = $alien->libs;
  my $cflags = $alien->cflags;

=head1 DESCRIPTION

See the documentation of L<Alien::Base> for details on the API of this module.

This module builds a copy of Lua that it ships or picks up a liblua from the
system. It exposes the location of the installed headers and shared objects
via a simple API to use by downstream depenent modules.

=head2 Using LuaJIT

If you have L<Alien::LuaJIT> installed, you can pass the
C<luajit> option to the constructor to make C<Alien::Lua>
act as a shim for C<Alien::LuaJIT>:

  use Alien::Lua;
  my $alien = Alien::Lua->new(luajit => 1);
  my $libs = $alien->libs; # refers to luajit
  my $cflags = $alien->cflags; # refers to luajit

Note that if C<Alien::LuaJIT> is not available, the
C<luajit> option becomes a silent no-op.

After passing the C<luajit> option to the constructor,
you can check whether LuaJIT will be used with the C<luajit>
method of C<Alien::Lua>.

=head1 ADDITIONAL METHODS

=head2 luajit

Returns the C<Alien::LuaJIT> object used by the given instance,
if any (see above).

=head1 SEE ALSO

L<http://www.lua.org>

L<http://www.luajit.org>

L<Alien::LuaJIT>

L<Alien::Base>

=head1 AUTHOR

Steffen Mueller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
