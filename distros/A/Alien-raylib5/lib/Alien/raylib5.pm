use strict;
use warnings;
package Alien::raylib5;
our $VERSION = '0.02'; # VERSION

use parent 'Alien::Base';

1;
__END__

=pod

=encoding utf8

=head1 NAME

Alien::raylib5 - Alien distribution for raylib video game engine, version 5 and above

=head1 ABSTRACT

Alien distribution for Raylib version 5.5

=head1 VERSION

version 0.01

=head1 USAGE

Use L<Raylib::FFI>, which wraps this, instead. Otherwise, just use it like any
other Alien distro. Currently wraps raylib 5.5.

=head1 System requirements

Should build out of the box on macOS and Windows.
On an Ubuntu Linux a few additonal packages are required:

    sudo apt-get install -y libasound2-dev \
        libxcursor-dev libxinerama-dev mesa-common-dev \
        libx11-dev libxrandr-dev libxi-dev \
        libgl1-mesa-dev libglu1-mesa-dev

If you also think these should be packaged as Alien modules, shoot me a
pull request.

=head1 GIT REPOSITORY

L<http://github.com/perigrin/Alien-raylib5>

=head1 SEE ALSO

L<http://github.com/athreef/Alien-raylib>

L<Raylib Homepage|http://www.raylib.com>

L<Raylib::FFI> L<Graphics::Raylib> L<Graphics::Raylib::XS>

=head1 AUTHOR

Chris Prather C<< <chris at prather.org> >>, L<http://chris.prather.org>

based on the work of Ahmad Fatoum C<< <athreef@cpan.org> >>, L<http://a3f.at>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 Ahmad Fatoum

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
