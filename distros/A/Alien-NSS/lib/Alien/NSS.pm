package Alien::NSS;

use strict;
use warnings;

our $VERSION = '0.23';

use parent 'Alien::Base';

1;

__END__

=head1 NAME

Alien::NSS - Alien wrapper for NSS ( Network Security Services )

=head1 DESCRIPTION

This library provides an alien wrapper for NSS, the cryptographic
library that is ( among others ) used in Mozilla Firefox and Google Chrome.

=head1 SYNOPSIS

  use strict;
  use warnings;

  use Module::Build;
  use Alien::NSS;

  my $cflags = Alien::NSS->cflags;
  my $ldflags = Alien::NSS->libs;

  my $builder = Module::Build->new(
    module_name => 'my_lib',
    extra_compiler_flags => $cflags,
    extra_linker_flags => $ldflags,
    configure_requires => {
      'Alien::NSS => 0
    },
  );

  $builder->create_build_script;

=head1 INSTALLATION

L<Alien::NSS> uses the L<Module::Build> system for installation. The usual build
process is

 perl Build.PL
 ./Build
 ./Build test
 ./Build install

=head2 Build Flags

When running C<perl Build.PL>, certain command line flags may be passed:

=over 4

=item C<--help>

Print all possible additional command line parameters for Building
L<Alien::NSS>

=item C<--version=3_17_2>

Specify the NSS version that should be installed. In this example, 3.17.2.

=item C<--patchnss>

Apply a patch that deactivates CRL caching and checking during
verification. This prevents certain problems when trying to load a high
number of certificates into NSS. Apply only if you understand the
consequences.

=back

=head1 SOURCE REPOSITORY

L<https://github.com/0xxon/alien-nss>

=head1 AUTHOR

Johanna Amann, E<lt>johanna@cpan.orgE<gt>

=head1 LICENSE

This Library is subject to the terms of the Mozilla
Public License, v. 2.0. If a copy of the MPL was not
distributed with this library, You can obtain one at
http://mozilla.org/MPL/2.0/.
