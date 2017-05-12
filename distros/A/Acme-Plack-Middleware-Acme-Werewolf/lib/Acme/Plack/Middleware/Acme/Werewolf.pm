package Acme::Plack::Middleware::Acme::Werewolf;

use strict;
use warnings;

=pod

=head1 NAME

Acme::Plack::Middleware::Acme::Werewolf - Plack middleware of Acme::Apache::Werewolf

=head1 SYNOPSIS

  my $app = sub { ... };
  builder {
      enable "Acme::Werewolf", moonlength => 4;
      $app;
  };

=head1 DESCRIPTION

Plack middleware implementation of L<Acme::Apache::Werewolf>
which keeps werewolves out of your web site during the full moon.

See to L<Plack::Middleware::Acme::Werewolf>.

=head1 AUTHOR

Makamaka Hannyaharamitu, E<lt>makamaka[at]cpan.orgE<gt>

The author of L<Acme::Apache::Werewolf> is Rich Bowen.

=head1 COPYRIGHT AND LICENSE

Copyright 2013 by Makamaka Hannyaharamitu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

