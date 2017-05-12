package Alien::LuaJIT;
use 5.14.0;
use warnings;

our $VERSION = '2.0.2.1';
use parent 'Alien::Base';

1;
__END__

=head1 NAME

Alien::LuaJIT - Alien module for asserting a luajit is available

=head1 SYNOPSIS

  use Alien::LuaJIT;
  my $alien = Alien::LuaJIT->new;
  my $libs = $alien->libs;
  my $cflags = $alien->cflags;

=head1 DESCRIPTION

See the documentation of L<Alien::Base> for details on the API of this module.

This module builds a copy of LuaJIT that it ships or picks up a luajit from the
system. It exposes the location of the installed headers and shared objects
via a simple API to use by downstream depenent modules.

=head1 SEE ALSO

L<http://www.luajit.org>

L<Alien::Base>

=head1 AUTHOR

Steffen Mueller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
