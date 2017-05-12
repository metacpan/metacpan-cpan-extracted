package Alien::GEOS;

use strict;
use warnings;

our $VERSION = 0.01;
$VERSION = eval $VERSION;

use parent 'Alien::Base';

1;

__END__

=head1 NAME

Alien::GEOS - Alien library for GEOS

=head1 SYNOPSIS

 use strict;
 use warnings;
 use Module::Build;
 use Alien::GEOS;
 
 # Retrieve the Alien::GEOS configuration:
 my $alien = Alien::GEOS->new;
 
 # Create the build script:
 my $builder = Module::Build->new(
     module_name => 'My::GEOS::Wrapper',
     extra_compiler_flags => $alien->cflags(),
     extra_linker_flags => $alien->libs(),
     configure_requires => {
         'Alien::GEOS' => 0,
     },
 );
 $builder->create_build_script;

=head1 DESCRIPTION

Alien::GEOS provides a CPAN distribution for the GEOS library. In other
words, it installs GEOS library in a non-system folder and provides you with
the details necessary to include in and link to your C/XS code.

For documentation on the GEOS API, see
L<http://trac.osgeo.org/geos/>.

=head1 AUTHOR

Alessandro Ranellucci, C<< <aar@cpan.org> >>

=head1 BUGS

The best place to report bugs or get help for this module is to file Issues on
github:

    https://github.com/alexrj/Alien-GEOS/issues

Note that I do not maintain GEOS itself, only the Alien module for it.

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Alessandro Ranellucci

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

This licensing note doesn't affect the GEOS library. See its license for 
more information.
