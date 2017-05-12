package Astro::MapProjection;
use 5.006001;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
  miller_projection
  hammer_projection
  sinusoidal_projection
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw();

our $VERSION = '0.01';

require XSLoader;
XSLoader::load('Astro::MapProjection', $VERSION);

1;
__END__

=head1 NAME

Astro::MapProjection - A few simple map projections (Hammer, sinusoidal, ...)

=head1 SYNOPSIS

  use Astro::MapProjection qw/miller_projection hammer_projection sinusoidal_projection/;
  my ($x, $y) = hammer_projection($latitude, $longitude);

=head1 DESCRIPTION

Simple XS module that implements a few map projections (see below).
Let me know if you need any others.

=head2 EXPORT

None by default. You can choose to import the following functions:

  miller_projection
  hammer_projection
  sinusoidal_projection

=head1 PROJECTIONS

=head2 Hammer projection

An equal area map projection after Ernst Hammer.

  x = 2*sqrt(2) * cos(lat)*sin(long/2) /
      sqrt(1+cos(lat)*cos(long/2))
  y = sqrt(2)*sin(lat) / 
      sqrt(1+cos(lat)*cos(long/2))

L<http://en.wikipedia.org/wiki/Hammer_projection>

=head2 Sinusoidal projection

Pseudocylindrical equal-area map projection. Also called Sanson-Flamsteed
or Mercartor equal-area projection.

  x = (long-long_0)*cos(lat)
  y = lat

L<http://en.wikipedia.org/wiki/Sinusoidal_projection>

=head2 Miller cylindrical projection

  x = long
  y = 5/4 * ln(tan(pi/4 + 2/5 * lat))

L<http://en.wikipedia.org/wiki/Miller_cylindrical_projection>

=head1 SEE ALSO

For more general information on map projections: L<http://en.wikipedia.org/wiki/Map_projection>

=head1 AUTHOR

Steffen Mueller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
