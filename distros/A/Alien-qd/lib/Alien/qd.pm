package Alien::qd;

use strict;
use warnings;

our $VERSION = 0.01;
$VERSION = eval $VERSION;

use parent 'Alien::Base';

1;

__END__

=head1 NAME

Alien::qd - Alien library for libqd

=head1 SYNOPSIS

 use strict;
 use warnings;
 use Module::Build;
 use Alien::qd;
 
 # Retrieve the Alien::qd configuration:
 my $alien = Alien::qd->new;
 
 # Create the build script:
 my $builder = Module::Build->new(
     module_name => 'My::qd::Wrapper',
     extra_compiler_flags => $alien->cflags(),
     extra_linker_flags => $alien->libs(),
     configure_requires => {
         'Alien::qd' => 0,
     },
 );
 $builder->create_build_script;

=head1 DESCRIPTION

Alien::qd provides a CPAN distribution for the qd library. In other
words, it installs qd's library in a non-system folder and provides you with
the details necessary to include in and link to your C/XS code.

For documentation on the qd's API, see
L<http://crd-legacy.lbl.gov/~dhbailey/mpdist/>.

=head1 AUTHOR

Alessandro Ranellucci, C<< <aar@cpan.org> >>

=head1 BUGS

The best place to report bugs or get help for this module is to file Issues on
github:

    https://github.com/alexrj/Alien-qd/issues

Note that I do not maintain qd itself, only the Alien module for it.

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Alessandro Ranellucci

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

This licensing note doesn't affect the shipped libqd archive. See its license for 
more information.
