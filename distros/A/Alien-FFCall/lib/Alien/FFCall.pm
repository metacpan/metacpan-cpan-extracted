package Alien::FFCall;

use strict;
use warnings;

our $VERSION = "0.03";
$VERSION = eval $VERSION;

use parent 'Alien::Base';

1;

__END__

=head1 NAME

Alien::FFCall - Alien library for FFCall

=head1 SYNOPSIS

I would encourage you to look at L<FFI> if you want a Perl-level wrapper to
FFCall. And generally you should be using L<FFI::Platypus> or L<FFI::Raw>
rather than L<FFI>. That said, you're reading this document. So here goes.

If you want to write your own XS-based interface to FFCall, your F<Build.PL>
file should say:

 use strict;
 use warnings;
 use Module::Build;
 use Alien::FFCall;
 
 # Retrieve the Alien::FFCall configuration:
 my $alien = Alien::FFCall->new;
 
 # Create the build script:
 my $builder = Module::Build->new(
     module_name => 'My::FFCall::Wrapper',
     extra_compiler_flags => $alien->cflags(),
     extra_linker_flags => $alien->libs(),
     configure_requires => {
         'Alien::FFCall' => 0,
     },
 );
 $builder->create_build_script;

Your module (.pm) file should look like this:

 package My::FFCall::Wrapper;
 
 use strict;
 use warnings;
 
 our $VERSION = '0.01';
 
 require XSLoader;
 XSLoader::load('My::FFCall::Wrapper');
 
 ... perl-level code goes here ...

Your XS file should look like this:

 #include "EXTERN.h"
 #include "perl.h"
 #include "XSUB.h"
 
 #include <avcall.h>
 #include <callback.h>
 
 ... normal XS stuff goes here, making use of the FFCall API ...

=head1 DESCRIPTION

Alien::FFCall provides a CPAN distribution for the FFCall library. In other
words, it installs FFCall's library in a non-system folder and provides you with
the details necessary to include in and link to your C/XS code.

For documentation on the FFCall's API, see
L<http://www.haible.de/bruno/packages-ffcall.html>.

=head1 AUTHOR

David Mertens, C<< <dcmertens.perl at gmail.com> >>

=head1 BUGS

The best place to report bugs or get help for this module is to file Issues on
github:

    https://github.com/run4flat/Alien-FFCall/issues

Note that FFCall is no longer maintained and has been superseeded by
libffi. Bear in mind, then, that I am the maintainer of this module, not
FFCall itself.

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Northwestern University

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
