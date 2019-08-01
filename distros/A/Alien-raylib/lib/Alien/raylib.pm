use strict;
use warnings;
package Alien::raylib;

# ABSTRACT: Alien distribution for Raylib
our $VERSION = '0.025'; # VERSION

use parent 'Alien::Base';

=pod

=encoding utf8

=head1 NAME

Alien::raylib - Alien distribution for raylib video game engine


=head1 VERSION

version 0.025

=head1 USAGE

Use L<Graphics::Raylib::XS>, which wraps this in XS, instead. Otherwise, just use it like any other Alien distro. Currently wraps raylib v2.1-dev (and a few extra commits, see the C<alienfile> in this distribution)

=head1 System requirements

Should build out of the box on macOS and Windows.
On an Ubuntu Linux a few additonal packages are required:

    sudo apt-get install -y libasound2-dev \
        libxcursor-dev libxinerama-dev mesa-common-dev \
        libx11-dev libxrandr-dev libxi-dev \
        libgl1-mesa-dev libglu1-mesa-dev

If you also think these should be packaged as L<Alien> modules, shoot me a L<pull request|https://github.com/athreef/Alien-raylib/pulls>.

=cut


1;
__END__

=head1 GIT REPOSITORY

L<http://github.com/athreef/Alien-raylib>

=head1 SEE ALSO

L<Raylib Homepage|http://www.raylib.com>

L<Graphics::Raylib> L<Graphics::Raylib::XS>

=head1 AUTHOR

Ahmad Fatoum C<< <athreef@cpan.org> >>, L<http://a3f.at>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 Ahmad Fatoum

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
