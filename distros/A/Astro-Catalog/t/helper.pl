
use strict;

=head1 NAME

helper - Test helper routines

=head1 SYNOPSIS

  compare_star( $star1, $star2 );
  compare_catalog( $cat1, $cat2 );


=head1 DESCRIPTION

Help routine for the test suite that are shared amongst more than
one test but that are not useful outside of the context of the test
suite.

=head1 FUNCTIONS

=over 4

=item B<compare_catalog>

Compare 2 catalogs.

  compare_catalog( $cat1, $cat2 );

where $cat1 is the catalogue to be tested, and $cat2 is the
reference catalogue.

Catalogs must be C<Astro::Catalog> objects. Currently simply compares
each star in teh catalog, without forcing a new sort (so order is
important).

=cut

sub main::compare_catalog {
  my ($cmpcat, $refcat) = @_;

  isa_ok( $refcat, "Astro::Catalog", "Check ref catalog type" );
  isa_ok( $cmpcat, "Astro::Catalog", "Check cmp catalog type" );

  # Star count
  is( $cmpcat->sizeof(), $refcat->sizeof(), "compare star count" );

  for my $i (0.. ($refcat->sizeof()-1)) {
    compare_star( $cmpcat->starbyindex($i), $refcat->starbyindex($i));
  }
}

=item B<compare_mpc_catalog>

Compare two MPC catalogues.

  compare_mpc_catalog( $cat1, $cat2 );

where $cat1 is the catalogue to be tested, and $cat2 is the
reference catalogue.

Catalogs must be C<Astro::Catalog> objects. Currently simply compares
each star in teh catalog, without forcing a new sort (so order is
important).

This method differs from compare_catalog() in that this one does not
do direct comparisons between RA and Dec for the two catalogues; it
only checks to make sure that the tested star is within one arcminute
of the reference star. It also sorts both catalogues by RA. This helps
compensate for the changing coordinates of minor planets as returned
from the MPC.

=cut

sub main::compare_mpc_catalog {
  my ($cmpcat, $refcat) = @_;

  isa_ok( $refcat, "Astro::Catalog", "Check ref catalog type" );
  isa_ok( $cmpcat, "Astro::Catalog", "Check cmp catalog type" );

  $refcat->sort_catalog( "ra" );
  $cmpcat->sort_catalog( "ra" );

  # Star count
  is( $cmpcat->sizeof(), $refcat->sizeof(), "compare star count" );

  for my $i (0.. ($refcat->sizeof()-1)) {
    compare_mpc_star( $cmpcat->starbyindex($i), $refcat->starbyindex($i));
  }
}

=item B<compare_star>

Compare the contents of two stars. Currently compares position, ID
and filters.

  compare_star( $star1, $star2 );

where $star1 is the star to be tested and $star2 is the
reference star.

=cut

sub compare_star {
  my ($cmpstar, $refstar) = @_;

  isa_ok( $refstar, "Astro::Catalog::Item", "Check ref star type");
  isa_ok( $cmpstar, "Astro::Catalog::Item", "Check cmp star type");

  is( $cmpstar->id(), $refstar->id(), "compare star ID" );

  # Distance is okay if we are within 1 arcsec
  my $maxsec = 1;
  my $radsep = $refstar->coords->distance( $cmpstar->coords );

  if (!defined $radsep) {
    # did not get any value. Too far away
    ok( 0, "Error calculating star separation. Too far?");
  } else {
    my $assep = $radsep->arcsec;
    ok( $assep < $maxsec, "compare distance between stars ($assep<$maxsec arcsec)" );
  }


  # these are not really useful given that we do a separation
  # test
  is( $cmpstar->ra(), $refstar->ra(), "compare star RA" );
  is( substr($cmpstar->dec(),0,9),
      substr($refstar->dec(),0,9),
      "Compare [truncated] star Dec" );

  # Compare field if the reference has a field
  if (defined $refstar->field) {
    is($cmpstar->field, $refstar->field, "Compare field");
  }

  # Filter comparisons
  my @cmp_filters = $cmpstar->what_filters();
  my @ref_filters = $refstar->what_filters();
  is( scalar(@cmp_filters), scalar(@ref_filters), "compare filter count");

  # Sort the filters.
  @cmp_filters = sort @cmp_filters;
  @ref_filters = sort @ref_filters;

  # Should loop over known filters rather than the filters
  # we got (just in case that is zero)
  foreach my $filter ( 0 ... $#ref_filters ) {
    is( $cmp_filters[$filter], $ref_filters[$filter],
        "compare filter $ref_filters[$filter]" );
    is( $cmpstar->get_magnitude($cmp_filters[$filter]),
        $refstar->get_magnitude($ref_filters[$filter]),
        "compare magnitude $ref_filters[$filter]");
    is( $cmpstar->get_errors($cmp_filters[$filter]),
        $refstar->get_errors($ref_filters[$filter]),
        "compare magerr $ref_filters[$filter]");
  }

  my @cmp_cols = $cmpstar->what_colours();
  my @ref_cols = $refstar->what_colours();

  #use Data::Dumper;
  #print Dumper( @cmp_cols );
  #print Dumper( @ref_cols );

  is(scalar(@cmp_cols), scalar(@ref_cols), "compare number of colors");

  # Sort the colours.
  @cmp_cols = sort @cmp_cols;
  @ref_cols = sort @ref_cols;

  foreach my $col ( 0 ... $#ref_cols ) {
    is( $cmp_cols[$col], $ref_cols[$col],"compare color $ref_cols[$col]" );
    is( $cmpstar->get_colour($cmp_cols[$col]),
	$refstar->get_colour($ref_cols[$col]),
	"compare value of color $ref_cols[$col]");
    is( $cmpstar->get_colourerr($cmp_cols[$col]),
	$refstar->get_colourerr($ref_cols[$col]),
	"compare color error $ref_cols[$col]" );
  }

  is( $cmpstar->quality(), $refstar->quality(), "check quality" );
  is( $cmpstar->field(), $refstar->field(), "check field" );
  is( $cmpstar->gsc(), $refstar->gsc() , "check GSC flag");
  is( $cmpstar->distance(), $refstar->distance() ,
      "check distance from field centre");
  is( $cmpstar->posangle(), $refstar->posangle(), "check posangle" );

}

=item B<compare_mpc_star>

Compare the contents of two stars. Currently compares position, ID
and filters.

  compare_star( $star1, $star2 );

where $star1 is the star to be tested and $star2 is the
reference star.

This method differs from compare_star in that it does not do
separate RA and Dec comparisons; it checks to see if the tested
star is within one arcminute of the reference star.

=cut

sub compare_mpc_star {
  my ($cmpstar, $refstar) = @_;

  isa_ok( $refstar, "Astro::Catalog::Star", "Check ref star type");
  isa_ok( $cmpstar, "Astro::Catalog::Star", "Check cmp star type");

  is( $cmpstar->id(), $refstar->id(), "compare star ID" );

  # Distance is okay if we are within 120 arcsec
  my $maxsec = 120;
  my $radsep = $refstar->coords->distance( $cmpstar->coords );

  if (!defined $radsep) {
    # did not get any value. Too far away
    ok( 0, "Error calculating star separation. Too far?");
  } else {
    my $assep = $radsep->arcsec;
    ok( $assep < $maxsec, "compare distance between stars ($assep<$maxsec arcsec)" );
  }


  # Compare field if the reference has a field
  if (defined $refstar->field) {
    is($cmpstar->field, $refstar->field, "Compare field");
  }


  # Filter comparisons
  my @cmp_filters = $cmpstar->what_filters();
  my @ref_filters = $refstar->what_filters();
  is( scalar(@cmp_filters), scalar(@ref_filters), "compare filter count");

  # Should loop over known filters rather than the filters
  # we got (just in case that is zero)
  foreach my $filter ( 0 ... $#ref_filters ) {
    is( $cmp_filters[$filter], $ref_filters[$filter],
	"compare filter $ref_filters[$filter]" );
    is( $cmpstar->get_magnitude($cmp_filters[$filter]),
	$refstar->get_magnitude($ref_filters[$filter]),
	"compare magnitude $ref_filters[$filter]");
    is( $cmpstar->get_errors($cmp_filters[$filter]),
	$refstar->get_errors($ref_filters[$filter]),
	"compare magerr $ref_filters[$filter]");
  }

  my @cmp_cols = $cmpstar->what_colours();
  my @ref_cols = $refstar->what_colours();
  is(scalar(@cmp_cols), scalar(@ref_cols), "compare number of colors");

  foreach my $col ( 0 ... $#ref_cols ) {
    is( $cmp_cols[$col], $ref_cols[$col],"compare color $ref_cols[$col]" );
    is( $cmpstar->get_colour($cmp_cols[$col]),
	$refstar->get_colour($ref_cols[$col]),
	"compare value of color $ref_cols[$col]");
    is( $cmpstar->get_colourerr($cmp_cols[$col]),
	$refstar->get_colourerr($ref_cols[$col]),
	"compare color error $ref_cols[$col]" );
  }

  is( $cmpstar->quality(), $refstar->quality(), "check quality" );
  is( $cmpstar->field(), $refstar->field(), "check field" );
  is( $cmpstar->gsc(), $refstar->gsc() , "check GSC flag");
  is( $cmpstar->distance(), $refstar->distance() ,
      "check distance from field centre");
  is( $cmpstar->posangle(), $refstar->posangle(), "check posangle" );

}

=back

=head1 USAGE

Requires that your tests are written using C<Test::More>
and that the top of each test includes the code:

  my $p = ( -d "t" ?  "t/" : "");
  do $p."helper.pl" or die "Error reading test functions: $!";

This allows the test to be run from inside or outside the
test directory.

=head1 SEE ALSO

L<Test::More>

=head1 COPYRIGHT

Copyright (C) 2001-2003 University of Exeter. All Rights Reserved.
Some modificiations Copyright (C) 2003 Particle Physics and Astronomy
Research Council. All Rights Reserved.

This program was written as part of the eSTAR project and is free software;
you can redistribute it and/or modify it under the terms of the GNU Public
License.

=head1 AUTHORS

Alasdair Allan E<lt>aa@astro.ex.ac.ukE<gt>,
Tim Jenness E<lt>tjenness@cpan.orgE<gt>,
Brad Cavanagh E<lt>b.cavanagh@jach.hawaii.eduE<gt>

=cut

1;
