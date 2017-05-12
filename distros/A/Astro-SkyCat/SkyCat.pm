package Astro::SkyCat;

=head1 NAME

Astro::SkyCat - Interface to the ESO SkyCat library

=head1 SYNOPSIS


  use Astro::SkyCat;

  $cat = Astro::SkyCat->Open("gsc\@eso");

  $q = new Astro::SkyCat::Query();
  $q->width(2.0);
  $q->height(3.5);

  $pos = new Astro::SkyCat::WorldCoords(3,19,48,41,30,39);
  $q->pos( $pos );

  $qr = new Astro::SkyCat::QueryResult();
  $nrows = $cat->query($q, "/tmp/file", $qr);

  foreach ($cat->colNames() ) {
    print "Column: $_  Value: ", $qr->get(1,$_), "\n";
  }



=head1 DESCRIPTION

This module provides a perl interface to the ESO SkyCat library.
The library can be used to retrieve catalogues and astronomical
images.

=cut


require Exporter;
require DynaLoader;

use strict;
use Carp;
use vars qw(@ISA $VERSION );

@ISA = qw/ DynaLoader /;
$VERSION = "0.01";

bootstrap Astro::SkyCat;

package Astro::SkyCat::WorldOrImageCoords;

sub __x {}

package Astro::SkyCat::WorldCoords;

use base qw/ Astro::SkyCat::WorldOrImageCoords /;


=head1 ROUTINES


=head1 AUTHORS

Tim Jenness E<lt>t.jenness@jach.hawaii.eduE<gt>

=head1 COPYRIGHT

Copyright (C) 2001 Particle Physics and Research Council.
All Rights Reserved.

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut

1;
