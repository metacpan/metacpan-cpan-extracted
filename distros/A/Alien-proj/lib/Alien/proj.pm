package Alien::proj;

use strict;
use warnings;
use parent qw( Alien::Base );

our $VERSION = '1.05';


1;

__END__

=head1 NAME

Alien::proj - Compile the PROJ library

=head1 BUILD STATUS
 
=begin HTML
 
<p>
    <img src="https://img.shields.io/badge/perl-5.10+-blue.svg" alt="Requires Perl 5.10+" />
    <a href="https://travis-ci.org/shawnlaffan/perl-alien-proj"><img src="https://travis-ci.org/shawnlaffan/perl-alien-proj.svg?branch=master" /></a>
    <a href="https://ci.appveyor.com/project/shawnlaffan/perl-alien-proj"><img src="https://ci.appveyor.com/api/projects/status/0j4yh071yw7xyjxx?svg=true" /></a>
</p>

=end HTML

=head1 SYNOPSIS

    use Alien::proj;

    
=head1 DESCRIPTION

PROJ is a generic coordinate transformation software.  See L<https://proj.org/about.html>.

This Alien package is probably most useful for compilation of other modules, e.g. L<Geo::GDAL::FFI>.

The Proj library can be accessed from Perl code via the L<Geo::Proj4> package.

Note: As of version 1.05, share installs will not install version 7 or above.
Version 7 needs libtiff and curl support, the latter of which needs
some implementation work.


=head1 User defined config args

User defined arguments can be passed to the configure script for share install
using the ALIEN_PROJ_CONFIG_ARGS environment variable. 

=head1 REPORTING BUGS

Please send any bugs, suggestions, or feature requests to 
L<https://github.com/shawnlaffan/perl-alien-proj/issues>.

=head1 SEE ALSO

L<Geo::Proj4>

L<Geo::GDAL::FFI>

L<Alien::geos::af>

L<Alien::gdal>

L<Alien::proj4> (if you need to stay on proj version 4)



=head1 AUTHORS

Shawn Laffan, E<lt>shawnlaffan@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE


Copyright 2018- by Shawn Laffan


This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
