package Alien::libsecp256k1;
$Alien::libsecp256k1::VERSION = '0.060001';
use v5.10;
use strict;
use warnings;

use parent 'Alien::Base';

1;

__END__

=head1 NAME

Alien::libsecp256k1 - Perl builder for libsecp256k1

=head1 SYNOPSIS

See L<Alien::Build::Manual::AlienUser>.

=head1 DESCRIPTION

This module may be used by other modules that require
L<libsecp256k1|https://github.com/bitcoin-core/secp256k1>. It will try to
detect whether this library is installed, and install it for other CPAN modules
to use.

The module installs the library version C<v0.6.0>. It may be updated to install
new versions when they become available. The library is bundled together with
the module, and the signature of the library's release has been verified before
releasing the module.

=head2 Testing

This alien skips building or running libsecp256k1 tests by default because it
requires much more time than building the library alone. To run them manually,
environmental variable C<ALIEN_LIBSECP256K1_RUN_TESTS> must be set to true
value during module install.

=head1 SEE ALSO

L<Alien::Build>

=head1 AUTHOR

Bartosz Jarzyna E<lt>bbrtj.pro@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Bartosz Jarzyna

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

The bundled libsecp256k1 is licensed under MIT license.

