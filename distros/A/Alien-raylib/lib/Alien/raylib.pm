use strict;
use warnings;
package Alien::raylib;

# ABSTRACT: Alien distribution for Raylib
our $VERSION = '0.006'; # VERSION

use parent 'Alien::Base';

=pod

=encoding utf8

=head1 NAME

Alien::raylib - Alien distribution for raylib video game engine


=head1 VERSION

version 0.006

=head1 USAGE

Use L<Graphics::Raylib::XS>, which wraps this in XS, instead. Otherwise, just use it like any other Alien distro. Currently wraps raylib 1.9.1-dev (and a few extra commits L<ca921e5a53fdd3412f5f81e3a739f54d68cb63a7|https://github.com/raysan5/raylib/commit/ca921e5a53fdd3412f5f81e3a739f54d68cb63a7>, specifically)

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
