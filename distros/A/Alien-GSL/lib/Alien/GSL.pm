package Alien::GSL;

use strict;
use warnings;
use 5.008001;

our $VERSION = '1.03';

use base 'Alien::Base';

1;

=head1 NAME

Alien::GSL - Easy installation of the GSL library

=head1 SYNOPSIS

  # Build.PL
  use Alien::GSL;
  use Module::Build 0.28; # need at least 0.28

  my $builder = Module::Build->new(
    configure_requires => {
      'Alien::GSL' => '1.00', # first Alien::Base-based release
    },
    ...
    extra_compiler_flags => Alien::GSL->cflags,
    extra_linker_flags   => Alien::GSL->libs,
    ...
  );

  $builder->create_build_script;


  # lib/MyLibrary/GSL.pm
  package MyLibrary::GSL;

  use Alien::GSL; # dynaload gsl

  ...

=head1 DESCRIPTION

Provides the Gnu Scientific Library (GSL) for use by Perl modules, installing it if necessary.
This module relies heavily on the L<Alien::Base> system to do so.
To avoid documentation skew, the author asks the reader to learn about the capabilities provided by that module rather than repeating them here.

=head1 COMPATIBILITY

Since version 1.00, L<Alien::GSL> relies on L<Alien::Base>.
Releases before that version warned about alpha stability and therefore no compatibility has been provided.
There were no reverse dependencies on CPAN at the time of the change.

From version 1.00, compability is provided by the L<Alien::Base> project itself which is quite concerned about keeping stability.
Future versions are expected to maintain compatibilty and failure to do so is to be considered a bug.
Of course this does not apply to the GSL library itself, though the author expects that the GNU project will provide the compatibility guarantees for that library as well.

=head1 SEE ALSO

=over

=item *

L<Alien::Base>

=item *

L<PDL::Modules/"GNU SCIENTIFIC LIBRARY">

=item *

L<PerlGSL>

=item *

L<Math::GSL>

=back

=head1 SOURCE REPOSITORY

L<https://github.com/PerlAlien/Alien-GSL>

=head1 AUTHOR

Joel Berger, E<lt>joel.a.berger@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011-2015 by Joel Berger

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


