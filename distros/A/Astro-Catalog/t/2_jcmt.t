#!perl

# Make sure we can read a JCMT format catalogue. In this case
# it is the pointing catalogue.

# Author: Tim Jenness (tjenness@cpan.org)
# Copyright (C) 2003-2005 Particle Physics and Astronomy Research Council

use strict;
use warnings;
use Test::More tests => 1772;

require_ok('Astro::Catalog::Item');
require_ok('Astro::Catalog');

# Create a new catalogue from the DATA handle
my $cat = new Astro::Catalog(Format => 'JCMT', Data => \*DATA);

isa_ok($cat, "Astro::Catalog");

my $total = 353;
is($cat->sizeof, $total, "count number of sources [inc planets]");

# check that we are using Astro::Coords and Astro::Catalog::Item

isa_ok($cat->allstars->[0], "Astro::Catalog::Item");
isa_ok($cat->allstars->[0]->coords, "Astro::Coords");

# The remaining tests actually test the catalog filtering
# search by substring
my @results = $cat->filter_by_id("3C");
is(scalar(@results), 6, "search by ID - \"3C\"");

for (@results) {
    print "# Name: " . $_->id . "\n";
}

# search by radius
my $refcoords = new Astro::Coords(
        ra => "23:14:00",
        dec => "61:27:00",
        type => "J2000");

# 10 arcmin
$cat->reset_list;
my $limit = Astro::Coords::Angle->new(10.0, units => "arcmin");
@results = $cat->filter_by_distance($limit->radians, $refcoords);
is(scalar(@results), 4, "search by radius");

# search for string
@results = $cat->filter_by_id(qr/^N7538IRS1$/i);
is(scalar(@results), 3, "search by full name");

# Check a specific velocity
$cat->reset_list;
my ($gl) = $cat->popstarbyid("GL490");
is($gl->coords->rv(), -12.5,"GL490 velocity");

# Check to see if line velocity range is defined.
my $misc = $gl->misc;
ok(! defined($misc->{'velocity_range'}), "GL490 line velocity range");

# Retrieve an object whose velocity range is defined.
$cat->reset_list;
my ($gl2477) = $cat->popstarbyid("GL2477");

is($gl2477->misc->{'velocity_range'}, '50.0', "GL2477 line velocity range");

# search for coords
$cat->reset_list;
@results = $cat->filter_by_cb(sub {substr($_[0]->ra,0,8) eq "02 22 39"});
is(scalar(@results), 1, "search by exact ra match");

# Write catalog
my $outcat = "catalog$$.dat";
$cat->reset_list;
$cat->write_catalog(Format => 'JCMT', File => "catalog$$.dat");
ok(-e $outcat, "Check catalog file was created");

# re-read it for comparison
my $cat3 = new Astro::Catalog(Format => 'JCMT', File => $outcat);

# Because of duplicates, we first go through and create a hash indexed by ID
my %hash1 = form_hash($cat);
my %hash2 = form_hash($cat3);
is(scalar keys %hash2, scalar keys %hash1, "Compare count");

for my $id (keys %hash1) {
    my $s1 = $hash1{$id};
    my $s2 = $hash2{$id};

    if (defined $s1 && defined $s2) {
        SKIP: {
            skip "HOLO source moves on the sky", 1 if ($id eq 'HOLO');
            my $d = $s1->coords->distance($s2->coords);
            ok($d->arcsec < 0.1, "Check coordinates $id");
        }
        SKIP: {
            skip "Only Equatorial coordinates have velocity", 3
                unless $s1->coords->type eq 'RADEC';
            is(sprintf("%.1f", $s2->coords->rv), sprintf("%.1f", $s1->coords->rv), "Compare velocity");
            is($s2->coords->vdefn, $s1->coords->vdefn, "Compare vel definition");
            is($s2->coords->vframe, $s1->coords->vframe, "Compare vel frame");

            my $s1misc = $s1->misc;
            my $s2misc = $s2->misc;
            if (defined($s1misc) && defined($s2misc)) {
                if (defined($s1misc->{'velocity_range'}) && defined($s2misc->{'velocity_range'})) {
                    is(sprintf( "%.2f", $s1misc->{'velocity_range'} ), sprintf( "%.2f", $s2misc->{'velocity_range'} ), "Compare line velocity range");
                }
                if (defined($s1misc->{'flux850'}) && defined($s2misc->{'flux850'})) {
                    is(sprintf( "%.2f", $s1misc->{'flux850'} ), sprintf( "%.2f", $s2misc->{'flux850'} ), "Compare 850-micron flux");
                }
            }
        }
    }
    else {
        # one of them is not defined
        if (!defined $s1 && !defined $s2) {
            ok(0, "ID $id exists in neither catalog");
        }
        elsif (!defined $s1) {
            ok(0, "ID $id does not exist in original catalog");
        }
        else {
            ok(0, "ID $id does not exist in new catalog");
        }

        SKIP: {
            skip "One of the coordinates is not defined", 3;
        }
    }
}

# and remove it
unlink $outcat;

# Test object constructor fails (should be in Astro::Catalog tests)
eval {my $cat2 = new Astro::Catalog(Format => 'JCMT', Data => {});};
ok($@, "Explicit object constructor failure - hash ref");

exit;

# my %hash = form_hash($cat);
sub form_hash {
    my $cat = shift;

    my %hash;
    for my $s ($cat->allstars) {
        my $id = $s->id;
        if (exists $hash{$id}) {
            my $c1 = $s->coords;
            my $c2 = $hash{$id}->coords;
            if ($c1->distance($c2) == 0) {
                # fine. The same coordinate
            }
            else {
                warn "ID matches $id but coords differ\n";
            }
        }
        else {
            $hash{$id} = $s;
        }
    }
    return %hash;
}

__DATA__
*                              JCMT_CATALOG
*                              ============
* point2002.cat : 
*
* 20 Aug 2002
*    names of 0954+658 and 1739+522 correctly installed
*         
* 04 Jan 2002
*    This catalog is different from the previous version in these ways :
*
* 1. Several spectral-fivepoint objects were revealed as having
*    inaccurate coordinates. Previously, SIMBAD coordinates were used.
*    Size and sense of errors supported adoption of coordinates by 
*                Loup et al (1993, A&AS 99, 291)
*    (which formed the basis of the 1950.0 version of this catalog).
*    Loup show good correlation, for late type stars with HD numbers, 
*    with the Hipparcos catalog. 
*    Particular objects have caught the attention of observing staff
*    in the last couple of months (CIT6, V370Aur, V636Mon, all stars,
*    note) and in each case the Loup et al (1993) coordinates would
*    have provided better service. Previous updates for CIT6, IRC-10502,
*    GL865 superseded without loss of accuracy by Loup's coordinates.
*
************************************************************************
*
*  This catalogue is the new unified JCMT source catalogue. It can only be
*  used in software planes 136 or higher. 
*
*  SOURCE NAME	    (T1, A12)           source name
*  LONGITUDE        (T15,A,2I3,F7.3)    longitude (sign, hms/dms)
*  LATITUDE         (T30,A,2I3,F7.3)    latitude  (sign, dms)
*  COSYS            (T44,A2)            coordinate system code
*  VELOCITY         (T46,G12.2)         velocity (km/sec) (?f10.1)
*  FLUX             (n/a)               Flux [Jy/beam] or Peak antenna temperature [K]
*  VRANGE           (n/a)               velocity range of spectral line
*  VEL_DEF          (T70,A3)               velocity definition: LSR, HEL etc.
*  FRAME            (T75,A6)            velocity frame of reference RADIO, OPTICAL, RELATIVISTIC
*  COMMENTS         (n/a)               range of flux variations, integrated line intensity,
*                                       calibration standard, mode of observing etc.
*
*  NOTE:  The control task expects an entry for each column, even though some entries may never be used
*         (e.g. FLUX, which is informative only). If any of the columns: VELOCITY, FLUX, or VRANGE are
*         not applicable, PLEASE enter n/a in the appropriate column or 0.
*
*  The catalogue is organized in the following way:
*
*      TARGETS OF OPPORTUNITY
*      CONTINUUM POINTING SOURCES AND STANDARDS
*          BLAZARS I - most of those in the previous catalog
*          BLAZARS II - new from the ICRF lists
*          COMPACT HII regions, AGB stars, PMS stars
*      SPECTRAL LINE CALIBRATORS
*      SOURCE LIST FOR SPECTRAL LINE FIVEPOINTS
*      OBSERVATORY BACKUP PROGRAM
*
*  Revisions : 
*  1996 Jul 09 - GS  -
*  1996 Nov 24 - REH - Modified holography source position 
*  1997 Aug 29 - RMP/GHLS - Modified holography position
*  1999 Nov 03 - imc - updated coords to J2000, see notes
*  2001 Feb 23 - imc - updated 850um fluxes for 'new' blazars
*  2001 Mar 12 - imc - add need for 120" chop for DG Tau
*  2001 Jul 02 - imc - updated 0.85mm fluxes based on last 1.5years of data
*                       - 76% of original blazars 
*                       - 51% of new blazars 
*                       - all but 5 continuum (non-blazar) sources 
*  2002 Apr 10 - imc - updated HOLO position
*  2002 May 02 - imc - 2 candidates from EIR added, 1622-2**
*
* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
*  TARGETS OF OPPORTUNITY
* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
ALCOM           12 32 25.68  + 14 20 57.4  RJ    n/a     n/a   n/a   LSR  RADIO                          
* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
*
* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
*  CONTINUUM POINTING SOURCES : BLAZARS
*
* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
*
*  Coordinates for blazars taken from  
*     Kuhr et al.         1981 Astr. Ap. Suppl., 45, 367
*     Perley, R.A.        1982 A.J. 87, 859 
*     Hewitt & Burbridge  1987 Ap.J. Suppl. 63, 1-246
*     Edelson R.A.        1987 A.J. 94, 1150 
*
*  see http://www.jach.hawaii.edu/JACpublic/JCMT/pointing/point2000.html
*  for the contributions of each of these to this catalog, and for
*  the trasnformations etc leading to this version of the catalog.
*
* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
*
*SOURCE         RA            DEC          EQUI  VEL    FLUX  RANGE  FRAME DEF   Comments
*                                          NOX    -    0.85mm   -                observed range
* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

0003-066        00 06 13.893 - 06 23 35.33 RJ    n/a     0.9   n/a   LSR  RADIO  0.8 - 1.0 Jy (Jul 2001)
0048-097        00 50 41.318 - 09 29 05.21 RJ    n/a     0.4   n/a   LSR  RADIO  0.3 - 0.4 Jy (Jul 2001)
PKS0106         01 08 38.771 + 01 35 00.32 RJ    n/a     0.7   n/a   LSR  RADIO  0.6 - 1.0 Jy (Jul 2001)
0133+476        01 36 58.595 + 47 51 29.10 RJ    n/a     1.8   n/a   LSR  RADIO  2.2 - 1.8 Jy (Jul 2001) 
0149+218        01 52 18.059 + 22 07 07.70 RJ    n/a     0.3   n/a   LSR  RADIO  once, May 2001
0202+319        02 05 04.925 + 32 12 30.10 RJ    n/a     0.4   n/a   LSR  RADIO  0.2 - 0.7 Jy 
0212+735        02 17 30.813 + 73 49 32.62 RJ    n/a     0.2   n/a   LSR  RADIO    0.2     Jy (Jul 2001)
0215+015        02 17 48.955 + 01 44 49.70 RJ    n/a     0.3   n/a   LSR  RADIO  0.4 - 0.3 Jy (Jul 2001)
0219+428        02 22 39.612 + 43 02 07.80 RJ    n/a     0.3   n/a   LSR  RADIO    0.3     Jy (Jul 2001)
0221+067        02 24 28.428 + 06 59 23.34 RJ    n/a     0.2   n/a   LSR  RADIO  0.4 - 0.2 Jy (Jul 2001)
0224+671        02 28 50.051 + 67 21 03.03 RJ    n/a     0.5   n/a   LSR  RADIO    0.5     Jy (Jul 2001) 
0234+285        02 37 52.406 + 28 48 08.99 RJ    n/a     0.9   n/a   LSR  RADIO  1.2 - 0.9 Jy (Jul 2001) 
0235+164        02 38 38.930 + 16 36 59.27 RJ    n/a     1.1   n/a   LSR  RADIO  0.6 - 1.1 Jy (Jul 2001) 
0300+471        03 03 35.242 + 47 16 16.28 RJ    n/a     0.6   n/a   LSR  RADIO  once                    
0306+102        03 09 03.624 + 10 29 16.34 RJ    n/a     0.2   n/a   LSR  RADIO    0.2     Jy (Jul 2001)   
3C84            03 19 48.160 + 41 30 42.10 RJ    n/a     0.9   n/a   LSR  RADIO  0.7 - 1.7 Jy (Jul 2001)
0336-019        03 39 30.938 - 01 46 35.80 RJ    n/a     1.2   n/a   LSR  RADIO  1.6 - 1.2 Jy (Jul 2001)
0355+508        03 59 29.747 + 50 57 50.16 RJ    n/a     1.9   n/a   LSR  RADIO  1.9 - 1.6 Jy (Jul 2001) 
0420-014        04 23 15.801 - 01 20 33.07 RJ    n/a     3.5   n/a   LSR  RADIO  1.5 - 3.5 Jy (Jul 2001)
0422+004        04 24 46.842 + 00 36 06.33 RJ    n/a     0.7   n/a   LSR  RADIO  once                    
3C120           04 33 11.096 + 05 21 15.62 RJ    n/a     0.3   n/a   LSR  RADIO  once 0.3 Jy (Jul 2001) 
PKS0438         04 40 17.180 - 43 33 08.60 RJ    n/a     0.4   n/a   LSR  RADIO  once                    
0454-234        04 57 03.179 - 23 24 52.02 RJ    n/a     0.9   n/a   LSR  RADIO  0.5 - 0.9 Jy (Jul 2001) 
0458-020        05 01 12.810 - 01 59 14.26 RJ    n/a     0.4   n/a   LSR  RADIO  0.3 - 0.4 Jy (Jul 2001)
0521-365        05 22 57.985 - 36 27 30.85 RJ    n/a     0.5   n/a   LSR  RADIO  2.5 - 0.5 Jy (Jul 2001) 
0528+134        05 30 56.417 + 13 31 55.15 RJ    n/a     0.7   n/a   LSR  RADIO  0.5 - 0.7 Jy (Jul 2001)
0529+075        05 32 38.998 + 07 32 43.35 RJ    n/a     0.7   n/a   LSR  RADIO  once                    
PKS0537         05 38 50.362 - 44 05 08.94 RJ    n/a     2.9   n/a   LSR  RADIO  4.0 - 2.9 Jy (Jul 2001) 
0552+398        05 55 30.806 + 39 48 49.17 RJ    n/a     0.4   n/a   LSR  RADIO  0.6 - 0.4 Jy (Jul 2001) 
0605-085        06 07 59.699 - 08 34 49.98 RJ    n/a     0.4   n/a   LSR  RADIO  0.6 - 0.4 Jy (Jul 2001)
0607-157        06 09 40.950 - 15 42 40.67 RJ    n/a     0.8   n/a   LSR  RADIO  1.0 - 0.8 Jy (Jul 2001) 
0642+449        06 46 32.026 + 44 51 16.59 RJ    n/a     0.4   n/a   LSR  RADIO  0.3 - 0.4 Jy (Jul 2001) 
0716+714        07 21 53.448 + 71 20 36.36 RJ    n/a     0.5   n/a   LSR  RADIO     0.5    Jy (Jul 2001) 
0727-115        07 30 19.112 - 11 41 12.60 RJ    n/a     1.0   n/a   LSR  RADIO    ~ 1.0   Jy (Jul 2001) 
0735+178        07 38 07.394 + 17 42 19.00 RJ    n/a     0.4   n/a   LSR  RADIO  0.5 - 0.4 Jy (Jul 2001) 
0736+017        07 39 18.034 + 01 37 04.62 RJ    n/a     1.5   n/a   LSR  RADIO  0.8 - 1.5 Jy (Jul 2001) 
0745+241        07 48 36.109 + 24 00 24.11 RJ    n/a     0.3   n/a   LSR  RADIO  0.2 - 0.3 Jy (Jul 2001) 
0748+126        07 50 52.046 + 12 31 04.83 RJ    n/a     0.3   n/a   LSR  RADIO     ~ 0.3  Jy (Jul 2001)                   
0754+100        07 57 06.643 + 09 56 34.85 RJ    n/a     0.8   n/a   LSR  RADIO  0.7 - 0.9 Jy 
0829+046        08 31 48.877 + 04 29 39.09 RJ    n/a     0.7   n/a   LSR  RADIO  0.2 - 1.3 Jy 
0836+710        08 41 24.365 + 70 53 42.17 RJ    n/a     1.4   n/a   LSR  RADIO  0.2 - 1.4 Jy 
OJ287           08 54 48.875 + 20 06 30.64 RJ    n/a     1.4   n/a   LSR  RADIO  0.7 - 2.0 Jy (Jul 2001)
0917+449        09 20 58.458 + 44 41 53.99 RJ    n/a     0.2   n/a   LSR  RADIO    ~ 0.2   Jy (Jul 2001)
0923+392        09 27 03.014 + 39 02 20.85 RJ    n/a     0.7   n/a   LSR  RADIO  1.5 - 0.7 Jy (Jul 2001) 
0954+658        09 58 47.245 + 65 33 54.82 RJ    n/a     0.5   n/a   LSR  RADIO  0.2 - 0.5 Jy (Jul 2001) 
1034-293        10 37 16.080 - 29 34 02.81 RJ    n/a     0.2   n/a   LSR  RADIO  0.2 - 0.6 Jy (Jul 2001)
1044+719        10 48 27.620 + 71 43 35.94 RJ    n/a     0.7   n/a   LSR  RADIO  0.4 - 0.7 Jy (Jul 2001) 
1055+018        10 58 29.605 + 01 33 58.82 RJ    n/a     2.0   n/a   LSR  RADIO  1.6 - 2.2 Jy (Jul 2001)
1147+245        11 50 19.212 + 24 17 53.84 RJ    n/a     0.5   n/a   LSR  RADIO  0.4 -                   
1156+295        11 59 31.834 + 29 14 43.83 RJ    n/a     0.8   n/a   LSR  RADIO  0.4 - 0.9 Jy (Jul 2001)
1213-172        12 15 46.752 - 17 31 45.40 RJ    n/a     0.2   n/a   LSR  RADIO  0.2 - 0.3 Jy (Jul 2001) 
3C273           12 29 06.700 + 02 03 08.60 RJ    n/a     3.7   n/a   LSR  RADIO  1.1 - 4.3 Jy (Jul 2001)
VirgoA          12 30 49.423 + 12 23 28.04 RJ    n/a     1.9   n/a   LSR  RADIO  1.4 - 1.9 Jy (Jul 2001)     
3C279           12 56 11.167 - 05 47 21.52 RJ    n/a     7.8   n/a   LSR  RADIO  1.8 - 18.2 Jy (Jul 2001)
1308+326        13 10 28.664 + 32 20 43.78 RJ    n/a     0.5   n/a   LSR  RADIO  0.3 - 0.5 Jy (Jul 2001)
1313-333        13 16 07.986 - 33 38 59.17 RJ    n/a     0.8   n/a   LSR  RADIO  0.1 - 1.8 Jy (Jul 2001) 
1334-127        13 37 39.783 - 12 57 24.69 RJ    n/a     2.8   n/a   LSR  RADIO  2.5 - 5.3 Jy (Jul 2001)
1413+135        14 15 58.817 + 13 20 23.71 RJ    n/a     0.4   n/a   LSR  RADIO  1.2 - 0.4 Jy (Jul 2001) 
1418+546        14 19 46.597 + 54 23 14.78 RJ    n/a     0.4   n/a   LSR  RADIO  0.3 - 0.9 Jy (Jul 2001)
1510-089        15 12 50.533 - 09 05 59.83 RJ    n/a     0.5   n/a   LSR  RADIO  0.4 - 0.7 Jy (Jul 2001)
1514-241        15 17 41.813 - 24 22 19.48 RJ    n/a     0.9   n/a   LSR  RADIO     ~ 0.9  Jy (Jul 2001) 
1538+149        15 40 49.492 + 14 47 45.88 RJ    n/a     0.3   n/a   LSR  RADIO  once                    
1548+056        15 50 35.269 + 05 27 10.45 RJ    n/a     0.3   n/a   LSR  RADIO  once                    
1606+106        16 08 46.203 + 10 29 07.78 RJ    n/a     0.5   n/a   LSR  RADIO  0.5 - 0.7 Jy 
1611+343        16 13 41.064 + 34 12 47.91 RJ    n/a     0.5   n/a   LSR  RADIO  0.3 - 0.6 Jy (Jul 2001)
1622-253        16 25 46.892 - 25 27 38.33 RJ    n/a     0.5   n/a   LSR  RADIO from EIR 20020501
1622-297        16 26 06.021 - 29 51 26.97 RJ    n/a     0.3   n/a   LSR  RADIO from EIR 20020501
1633+382        16 35 15.493 + 38 08 04.50 RJ    n/a     1.0   n/a   LSR  RADIO     ~ 1.0  Jy (Jul 2001) 
3C345           16 42 58.810 + 39 48 36.99 RJ    n/a     2.5   n/a   LSR  RADIO  2.0 - 3.5 Jy (Jul 2001) 
1657-261        17 00 53.154 - 26 10 51.72 RJ    n/a     0.2   n/a   LSR  RADIO  once Apr 2001
1730-130        17 33 02.706 - 13 04 49.55 RJ    n/a     1.7   n/a   LSR  RADIO  1.3 - 1.7 Jy (Jul 2001)
1739+522        17 40 36.978 + 52 11 43.41 RJ    n/a     0.1   n/a   LSR  RADIO  0.3 - 0.1 Jy (Jul 2001)                    
1741-038        17 43 58.856 - 03 50 04.62 RJ    n/a     1.1   n/a   LSR  RADIO  once                    
1749+096        17 51 32.819 + 09 39 00.73 RJ    n/a     0.3   n/a   LSR  RADIO  1.2 - 0.3 Jy (Jul 2001) 
1749+701        17 48 32.840 + 70 05 50.77 RJ    n/a     0.2   n/a   LSR  RADIO  once May 2001
1803+784        18 00 45.684 + 78 28 04.02 RJ    n/a     0.7   n/a   LSR  RADIO  0.8 - 0.7 Jy (Jul 2001)
1807+698        18 06 50.681 + 69 49 28.11 RJ    n/a     0.8   n/a   LSR  RADIO     ~ 0.8  Jy (Jul 2001) 
1823+568        18 24 07.068 + 56 51 01.49 RJ    n/a     1.1   n/a   LSR  RADIO  0.5 - 1.1 Jy (Jul 2001)
1908-202        19 11 09.653 - 20 06 55.11 RJ    n/a     0.7   n/a   LSR  RADIO  once May 2001                    
1921-293        19 24 51.056 - 29 14 30.12 RJ    n/a     5.5   n/a   LSR  RADIO  2.5 - 6.0 Jy (Jul 2001)
1923+210        19 25 59.605 + 21 06 26.16 RJ    n/a     0.5   n/a   LSR  RADIO  0.4 - 0.5 Jy (Jul 2001)
1928+738        19 27 48.495 + 73 58 01.57 RJ    n/a     0.4   n/a   LSR  RADIO    ~  0.4  Jy (Jul 2001)                    
1958-179        20 00 57.090 - 17 48 57.67 RJ    n/a     0.5   n/a   LSR  RADIO  0.5 - 0.8 Jy (Jul 2001)
2005+403        20 07 44.945 + 40 29 48.60 RJ    n/a     0.6   n/a   LSR  RADIO  0.3 -                   
2007+776        20 05 30.999 + 77 52 43.25 RJ    n/a     0.3   n/a   LSR  RADIO  0.5 - 0.3 Jy (Jul 2001) 
2008-159        20 11 15.711 - 15 46 40.25 RJ    n/a     0.6   n/a   LSR  RADIO  once                    
2021+317        20 23 19.017 + 31 53 02.31 RJ    n/a     0.3   n/a   LSR  RADIO    ~ 0.3   Jy (Jul 2001) 
2037+511        20 38 37.035 + 51 19 12.66 RJ    n/a     0.7   n/a   LSR  RADIO  once                    
2059+034        21 01 38.834 + 03 41 31.32 RJ    n/a     0.5   n/a   LSR  RADIO  once                    
2134+004        21 36 38.586 + 00 41 54.21 RJ    n/a     0.7   n/a   LSR  RADIO  0.5 - 0.7 Jy 
2145+067        21 48 05.459 + 06 57 38.60 RJ    n/a     1.2   n/a   LSR  RADIO  1.0 - 3.0 Jy (Jul 2001)
2155-304        21 58 52.065 - 30 13 32.12 RJ    n/a     0.1   n/a   LSR  RADIO  once 0.1 Jy (Jul 2001)              
2155-152        21 58 06.282 - 15 01 09.33 RJ    n/a     0.6   n/a   LSR  RADIO                          
BLLAC           22 02 43.291 + 42 16 39.98 RJ    n/a     1.9   n/a   LSR  RADIO  0.5 - 3.0 Jy (Jul 2001)
2201+315        22 03 14.976 + 31 45 38.27 RJ    n/a     0.9   n/a   LSR  RADIO  0.4 -                   
2223-052        22 25 47.259 - 04 57 01.39 RJ    n/a     3.0   n/a   LSR  RADIO  2.1 - 3.0 Jy (Jul 2001) 
2227-088        22 29 40.084 - 08 32 54.44 RJ    n/a     1.0   n/a   LSR  RADIO  0.8 - 1.4 Jy 
2230+114        22 32 36.409 + 11 43 50.90 RJ    n/a     0.4   n/a   LSR  RADIO  0.6 - 0.4 Jy (Jul 2001) 
2243-123        22 46 18.232 - 12 06 51.28 RJ    n/a     0.5   n/a   LSR  RADIO  0.4 - 0.5 Jy (Jul 2001) 
2251+158        22 53 57.748 + 16 08 53.56 RJ    n/a     6.1   n/a   LSR  RADIO  0.7 - 6.1 Jy (Jul 2001)
2255-282        22 58 05.963 - 27 58 21.26 RJ    n/a     3.1   n/a   LSR  RADIO  once 3.1 Jy (Jul 2001) 
2318+049        23 20 44.857 + 05 13 49.95 RJ    n/a     0.8   n/a   LSR  RADIO  0.3 - 0.8 Jy 
2345-167        23 48 02.609 - 16 31 12.02 RJ    n/a     0.5   n/a   LSR  RADIO  once                    
*
* The 6 sources below were not carried over from the original (RB) version
* due to inaccuracies in their positions, but they are repeated here in
* case of desperation - 3c111 and CenA in particular are too strong to
* discard completely.
*
3C111           04 15 00.61  + 37 54 19.5  RB    n/a     2.0   n/a   LSR  RADIO  2.5 - 2.0 Jy (Jul 2001)
0954+556        09 54 14.355 + 55 37 16.35 RB    n/a     0.3   n/a   LSR  RADIO  0.1 - 0.3 Jy
1219+285        12 19 01.12  + 28 30 36.45 RB    n/a     0.3   n/a   LSR  RADIO  0.2 - 0.4 Jy (Jul 2001)
CENA            13 22 31.8   - 42 45 30.0  RB    n/a     7.7   n/a   LSR  RADIO  7.3 - 21.1 Jy (Jul 2001)
1716+686        17 16 27.84  + 68 39 48.3  RB    n/a     0.4   n/a   LSR  RADIO  once
CygA            19 57 44.6   + 40 35 45.9  RB    n/a     0.7   n/a   LSR  RADIO  
*
* 76 of the next 78 blazars are new to this version of the catalog
* see http://www.jach.hawaii.edu/JACpublic/JCMT/pointing/point2000.html
* for a description of their inclusion.
* Two (0106+013 and 0430+052) are already listed above by their familiars
*      PKS0106  and   3c120).
* fluxes listed are either :
*      - the most recent determinations at 850um at JCMT (2000 02 23, imc) , 
*        in which case the date of the last measure and the ranges of previous measures 
*        made since ~1999 are shown in the last column, or
*      - they are (the original) extrapolations from other wavelengths.
*        These proved to be overly optimistic by about x2,
*        so have been reduced now by this factor, with a minimum of 0.2 Jy
*        so as to encourage at least one observation.
*
0016+731        00 19 45.786 + 73 27 30.02 RJ    n/a     0.2   n/a   LSR  RADIO 0.2 - 0.4 Jy (Jul 2001)
0035+413        00 38 24.844 + 41 37 06.00 RJ    n/a     0.1   n/a   LSR  RADIO ~0.1      Jy (Jul 2001)
0106+013        01 08 38.771 + 01 35 00.32 RJ    n/a     0.5   n/a   LSR  RADIO 0.6 - 1.0 Jy (Jul 2001)
0112-017        01 15 17.100 - 01 27 04.58 RJ    n/a     0.3   n/a   LSR  RADIO
0119+041        01 21 56.862 + 04 22 24.73 RJ    n/a     0.2   n/a   LSR  RADIO Aug2000
0134+329        01 37 41.299 + 33 09 35.13 RJ    n/a     0.2   n/a   LSR  RADIO
0135-247        01 37 38.347 - 24 30 53.89 RJ    n/a     0.3   n/a   LSR  RADIO 0.5 - 0.3 Jy (Jul 2001)
0138-097        01 41 25.832 - 09 28 43.67 RJ    n/a     0.2   n/a   LSR  RADIO
0229+131        02 31 45.894 + 13 22 54.72 RJ    n/a     0.1   n/a   LSR  RADIO <0.1 Jy (Jul 2001)
0239+108        02 42 29.171 + 11 01 00.73 RJ    n/a     0.2   n/a   LSR  RADIO
0333+321        03 36 30.108 + 32 18 29.34 RJ    n/a     0.3   n/a   LSR  RADIO Nov1999
0338-214        03 40 35.608 - 21 19 31.17 RJ    n/a     0.5   n/a   LSR  RADIO   0.5     Jy (Jul 2001)
0414-189        04 16 36.544 - 18 51 08.34 RJ    n/a     0.2   n/a   LSR  RADIO
0430+052        04 33 11.096 + 05 21 15.62 RJ    n/a     0.6   n/a   LSR  RADIO  once 0.3 Jy (Jul 2001)
0511-220        05 13 49.114 - 21 59 16.09 RJ    n/a     0.2   n/a   LSR  RADIO
0518+165        05 21 09.886 + 16 38 22.05 RJ    n/a     0.2   n/a   LSR  RADIO
0538+498        05 42 36.138 + 49 51 07.23 RJ    n/a     0.2   n/a   LSR  RADIO
0539-057        05 41 38.083 - 05 41 49.43 RJ    n/a     0.4   n/a   LSR  RADIO Nov1999
0648-165        06 50 24.582 - 16 37 39.73 RJ    n/a     0.2   n/a   LSR  RADIO
0723-008        07 25 50.640 - 00 54 56.54 RJ    n/a     0.5   n/a   LSR  RADIO   ~ 0.5    Jy (Jul 2001)
0742+103        07 45 33.060 + 10 11 12.69 RJ    n/a     0.2   n/a   LSR  RADIO
0743-006        07 45 54.082 - 00 44 15.54 RJ    n/a     0.2   n/a   LSR  RADIO
0808+019        08 11 26.707 + 01 46 52.22 RJ    n/a     0.3   n/a   LSR  RADIO
0814+425        08 18 16.000 + 42 22 45.41 RJ    n/a     0.4   n/a   LSR  RADIO 0.3 - 0.4 Jy (Jul 2001) 
0818-128        08 20 57.448 - 12 58 59.17 RJ    n/a     0.2   n/a   LSR  RADIO once Sep 2000
0823+033        08 25 50.338 + 03 09 24.52 RJ    n/a     0.6   n/a   LSR  RADIO 0.4 - 0.6 Jy (Jul 2001)
0828+493        08 32 23.217 + 49 13 21.04 RJ    n/a     0.5   n/a   LSR  RADIO Feb2001 0.4 - 0.9
0859+470        09 03 03.990 + 46 51 04.14 RJ    n/a     0.2   n/a   LSR  RADIO    ~ 0.2  Jy (Jul 2001)
0859-140        09 02 16.831 - 14 15 30.88 RJ    n/a     0.2   n/a   LSR  RADIO
0906+015        09 09 10.092 + 01 21 35.62 RJ    n/a     0.2   n/a   LSR  RADIO
0917+624        09 21 36.231 + 62 15 52.18 RJ    n/a     0.2   n/a   LSR  RADIO once Feb2001
0919-260        09 21 29.354 - 26 18 43.39 RJ    n/a     0.1   n/a   LSR  RADIO   ~ 0.1   Jy (Jul 2001) 
0925-203        09 27 51.824 - 20 34 51.23 RJ    n/a     0.2   n/a   LSR  RADIO
0955+326        09 58 20.950 + 32 24 02.21 RJ    n/a     0.2   n/a   LSR  RADIO
1011+250        10 13 53.429 + 24 49 16.44 RJ    n/a     0.2   n/a   LSR  RADIO
1012+232        10 14 47.065 + 23 01 16.57 RJ    n/a     0.5   n/a   LSR  RADIO 0.2 - 0.5 Jy (Jul 2001)
1053+815        10 58 11.535 + 81 14 32.68 RJ    n/a     0.3   n/a   LSR  RADIO Feb2001
1116+128        11 18 57.301 + 12 34 41.72 RJ    n/a     0.3   n/a   LSR  RADIO    ~  0.3 Jy (Jul 2001)
1124-186        11 27 04.392 - 18 57 17.44 RJ    n/a     0.3   n/a   LSR  RADIO 0.3 - 0.5 Jy (Jul 2001)
1127-145        11 30 07.053 - 14 49 27.39 RJ    n/a     0.2   n/a   LSR  RADIO
1128+385        11 30 53.283 + 38 15 18.55 RJ    n/a     0.3   n/a   LSR  RADIO Dec1999
1144+402        11 46 58.298 + 39 58 34.30 RJ    n/a     0.4   n/a   LSR  RADIO 0.3 - 0.6 Jy (Jul 2001)
1148-001        11 50 43.871 - 00 23 54.20 RJ    n/a     0.2   n/a   LSR  RADIO
1216+487        12 19 06.415 + 48 29 56.16 RJ    n/a     0.1   n/a   LSR  RADIO 0.1 - 0.2 Jy (Jul 2001)
1222+037        12 24 52.422 + 03 30 50.29 RJ    n/a     0.1   n/a   LSR  RADIO < 0.1 Jy (Jul 2001)
1243-072        12 46 04.232 - 07 30 46.57 RJ    n/a     0.3   n/a   LSR  RADIO
1244-255        12 46 46.802 - 25 47 49.29 RJ    n/a     0.4   n/a   LSR  RADIO 1.7 - 0.4 Jy (Jul 2001)
1252+119        12 54 38.256 + 11 41 05.90 RJ    n/a     0.2   n/a   LSR  RADIO
1302-102        13 05 33.015 - 10 33 19.43 RJ    n/a     0.7   n/a   LSR  RADIO
1328+307        13 31 08.288 + 30 30 32.96 RJ    n/a     0.3   n/a   LSR  RADIO Feb2000
1345+125        13 47 33.362 + 12 17 24.24 RJ    n/a     0.2   n/a   LSR  RADIO
1354-152        13 57 11.245 - 15 27 28.79 RJ    n/a     0.2   n/a   LSR  RADIO
1354+195        13 57 04.437 + 19 19 07.37 RJ    n/a     0.4   n/a   LSR  RADIO 0.3 - 0.4 Jy (Jul 2001)
1502+106        15 04 24.980 + 10 29 39.20 RJ    n/a     0.3   n/a   LSR  RADIO 0.2 - 0.4 Jy (Jul 2001)
1504-166        15 07 04.787 - 16 52 30.27 RJ    n/a     0.3   n/a   LSR  RADIO
1511-100        15 13 44.893 - 10 12 00.26 RJ    n/a     0.2   n/a   LSR  RADIO
1519-273        15 22 37.676 - 27 30 10.79 RJ    n/a     0.3   n/a   LSR  RADIO Feb2001
1600+335        16 02 07.263 + 33 26 53.07 RJ    n/a     0.15  n/a   LSR  RADIO Mar2000
1637+574        16 38 13.456 + 57 20 23.98 RJ    n/a     0.5   n/a   LSR  RADIO 0.1 - 1.0 Jy (Jul 2001)
1638+398        16 40 29.633 + 39 46 46.03 RJ    n/a     0.15  n/a   LSR  RADIO Jun2000
1642+690        16 42 07.849 + 68 56 39.76 RJ    n/a     0.7   n/a   LSR  RADIO 0.5 - 0.7 Jy (Jul 2001)
1655+077        16 58 09.011 + 07 41 27.54 RJ    n/a     0.4   n/a   LSR  RADIO 0.3 - 0.4 Jy (Jul 2001)
1656+477        16 58 02.780 + 47 37 49.23 RJ    n/a     0.2   n/a   LSR  RADIO 0.1 - 0.2 Jy (Jul 2001)
1717+178        17 19 13.048 + 17 45 06.44 RJ    n/a     0.3   n/a   LSR  RADIO once June 2001
1743+173        17 45 35.208 + 17 20 01.42 RJ    n/a     0.2   n/a   LSR  RADIO
1758+388        18 00 24.765 + 38 48 30.70 RJ    n/a     0.1   n/a   LSR  RADIO 0.2 - 0.1 Jy (Jul 2001)
1800+440        18 01 32.315 + 44 04 21.90 RJ    n/a     0.6   n/a   LSR  RADIO 0.4 - 0.6 Jy (Jul 2001)
1842+681        18 42 33.642 + 68 09 25.23 RJ    n/a     0.3   n/a   LSR  RADIO
1954+513        19 55 42.738 + 51 31 48.55 RJ    n/a     0.2   n/a   LSR  RADIO 0.3 - 0.2 Jy (Jul 2001)
2021+614        20 22 06.682 + 61 36 58.80 RJ    n/a     0.2   n/a   LSR  RADIO
2121+053        21 23 44.517 + 05 35 22.09 RJ    n/a     0.4   n/a   LSR  RADIO 0.7 - 0.4 Jy (Jul 2001)
2128-123        21 31 35.262 - 12 07 04.80 RJ    n/a     0.2   n/a   LSR  RADIO
2131-021        21 34 10.310 - 01 53 17.24 RJ    n/a     0.4   n/a   LSR  RADIO
2210-257        22 13 02.498 - 25 29 30.08 RJ    n/a     0.2   n/a   LSR  RADIO
2216-038        22 18 52.038 - 03 35 36.88 RJ    n/a     0.2   n/a   LSR  RADIO
2229+695        22 30 36.470 + 69 46 28.08 RJ    n/a     0.1   n/a   LSR  RADIO once 0.1 Jy (Jul 2001)
2234+282        22 36 22.471 + 28 28 57.41 RJ    n/a     0.6   n/a   LSR  RADIO 0.3 - 0.7 Jy (Jul 2001)
2344+092        23 46 36.839 + 09 30 45.51 RJ    n/a     0.2   n/a   LSR  RADIO
*
* - -- -- -- -- -- --  -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
*  CONTINUUM SOURCES : Compact HII regions, ABG and PMS - stars
* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
*
*  A few of these are secondary calibrators for SCUBA, some also serve as spectral line standards
*  Coordinates are either c - derived by coco (co-ordinate transformation) from 1950.0 FK4
*                                    - this is usually the case for non-stellar sources, where
*                                      submm & opt/NIR peaks may not coincide
*                      or s - as listed by Simbad (2000.0 FK5)
*                                    - this is usually reserved for stellar sources
* Fluxes - 2001 Jul - changed to 0.85mm fluxes, based on last 18months data. 
*                     data for HH1-2VLA, TWHya, M8E, ON-1, V645Cyg are the old 1.1mm values
* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
*SOURCE         RA            DEC          EQUI  VEL     FLUX  RANGE  FRAME DEF   Comments
*                                          NOX    -      0.85mm   -                c = coco  s = simbad
* - -- -- -- -- -- -- --  -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
W3(OH)          02 27 03.831 + 61 52 24.77 RJ  -   45.0 35.0   n/a   LSR  RADIO  c 
GL490           03 27 38.842 + 58 47 00.51 RJ  -   12.5  5.0   n/a   LSR  RADIO  c 
TTau            04 21 59.43  + 19 32 06.4  RJ  +    7.5  1.3   n/a   LSR  RADIO  s T Tauri star            
DGTau           04 27 04.7   + 26 06 17.   RJ  +    5.0  0.9   n/a   LSR  RADIO  s T Tauri star; use 120" chop            
L1551-IRS5      04 31 34.140 + 18 08 05.13 RJ  +    6.0  6.0   n/a   LSR  RADIO  c 
HLTau           04 31 38.4   + 18 13 59.   RJ  +    6.4  2.3   n/a   LSR  RADIO  s TTAu* - 2nd-ary flux calibrator
CRL618          04 42 53.597 + 36 06 53.65 RJ  -   21.7  4.5   90.0  LSR  RADIO  c Secondary flux calibrator
OMC1            05 35 14.373 - 05 22 32.35 RJ  +   10.0 99.9   n/a   LSR  RADIO  c use 150" chop for pointi
HH1-2VLA        05 36 22.837 - 06 46 06.57 RJ  +    8.0  0.8   n/a   LSR  RADIO  c                        
N2071IR         05 47 04.851 + 00 21 47.10 RJ  +    9.5 16.0   n/a   LSR  RADIO  c 
VYCMa           07 22 58.33  - 25 46 03.2  RJ  +   19.0  1.7   70.0  LSR  RADIO  s 
OH231.8         07 42 16.93  - 14 42 50.2  RJ  +   30.0  2.5  140.0  LSR  RADIO  c Secondary flux calibrator
IRC+10216       09 47 57.382 + 13 16 43.66 RJ  -   25.6  6.1   35.0  LSR  RADIO  c Secondary flux calibrator, var 1.8-2.8
TWHya           11 01 51.91  - 34 42 17.0  RJ  +    0.0  0.8   n/a   LSR  RADIO  s T Tauri star             
16293-2422      16 32 22.909 - 24 28 35.60 RJ  +    4.0 16.3   n/a   LSR  RADIO  c Secondary flux calibrator
G343.0          16 58 17.136 - 42 52 06.61 RJ  -   31.0 35.0   n/a   LSR  RADIO  c 
NGC6334I        17 20 53.445 - 35 47 01.67 RJ  -    6.9 60.0   n/a   LSR  RADIO  c 
G5.89           18 00 30.376 - 24 04 00.48 RJ  +   10.0 48.0   n/a   LSR  RADIO  c 
M8E             18 04 52.957 - 24 26 39.36 RJ  +   11.0  2.8   n/a   LSR  RADIO  c       
G10.62          18 10 28.661 - 19 55 49.76 RJ  -    3.5 50.0   n/a   LSR  RADIO  c 
G34.3           18 53 18.569 + 01 14 58.26 RJ  +   58.1 70.0   n/a   LSR  RADIO  c 
G45.1           19 13 22.079 + 10 50 53.42 RJ  +   48.0 11.0   n/a   LSR  RADIO  c 
K3-50           20 01 45.689 + 33 32 43.52 RJ  -   23.7 20.0   n/a   LSR  RADIO  c 
ON-1            20 10 09.146 + 31 31 37.67 RJ  +   11.8  4.7   n/a   LSR  RADIO  c 
GL2591          20 29 24.719 + 40 11 18.87 RJ  -    5.8  3.0   n/a   LSR  RADIO  c                        
W75N            20 38 36.433 + 42 37 34.49 RJ  +   12.5 35.0   n/a   LSR  RADIO  c 
MWC349          20 32 45.6   + 40 39 37.   RJ  -    6.6  1.9   n/a   LSR  RADIO  s True point source        
PVCep           20 45 54.39  + 67 57 38.8  RJ  +    3.0  1.2   n/a   LSR  RADIO  s                        
CRL2688         21 02 18.805 + 36 41 37.70 RJ  -   35.4  5.9   80.0  LSR  RADIO  c Secondary flux calibrator
NGC7027         21 07 01.593 + 42 14 10.18 RJ  +   26.0  5.0   50.0  LSR  RADIO  c 
V645Cyg         21 39 58.2   + 50 14 22.   RJ  -   43.7  0.9   n/a   LSR  RADIO  s                        
LKHA234         21 43 06.170 + 66 06 56.09 RJ  -   10.0  5.0   n/a   LSR  RADIO  c Herbig Be star           
N7538IRS1       23 13 45.346 + 61 28 10.32 RJ  -   58.0 33.0   n/a   LSR  RADIO  c                        
N7538IRS9       23 14 01.682 + 61 27 19.96 RJ  -   58.0  6.5   n/a   LSR  RADIO  c                        
*
* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
*
*   SPECTRAL LINE STANDARDS
*  
*   all 2000.0 FK5 coords derived by coco - see previous section
*   2001 10 19 - offsets updated for crl618, omc1, oh231.8, w75n, ngc7027
*                                                                                PS offset is for CO and isotopes
* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
W3(OH)          02 27 03.831 + 61 52 24.77 RJ  -   45.0 12.8   n/a   LSR  RADIO  PS -600,0 RJ
L1551-IRS5      04 31 34.140 + 18 08 05.13 RJ  +    6.0  2.4   n/a   LSR  RADIO  PS                ; seco
CRL618          04 42 53.597 + 36 06 53.65 RJ  -   21.7  3.2   90.0  LSR  RADIO  BMSW 180" AZ            
OMC1            05 35 14.373 - 05 22 32.35 RJ  +    10.0  72.  n/a   LSR  RADIO  PS 0, 2100 RJ
N2071IR         05 47 04.851 + 00 21 47.10 RJ  +    9.5  4.8   n/a   LSR  RADIO  PS 2400,0 RJ
OH231.8         07 42 16.93  - 14 42 50.2  RJ  +   30.0  1.3  140.0  LSR  RADIO  BMSW 300" AZ
IRC+10216       09 47 57.382 + 13 16 43.66 RJ  -   25.6  2.3   35.0  LSR  RADIO  PS 300,0 AZ
16293-2422      16 32 22.909 - 24 28 35.60 RJ  +    4.0  8.3   n/a   LSR  RADIO  PS -800,0 RJ
NGC6334I        17 20 53.445 - 35 47 01.67 RJ  -    6.9 30.0   n/a   LSR  RADIO  PS 2400,0 RJ
G34.3           18 53 18.569 + 01 14 58.26 RJ  +   58.1 31.2   n/a   LSR  RADIO  PS -3120,1800 RJ
W75N            20 38 36.433 + 42 37 34.49 RJ  +   12.5 11.6   n/a   LSR  RADIO  PS -1800,0 RJ
CRL2688         21 02 18.805 + 36 41 37.70 RJ  -   35.4  2.7   80.0  LSR  RADIO  BMSW 180" AZ            
NGC7027         21 07 01.593 + 42 14 10.18 RJ  +   26.0  3.7   50.0  LSR  RADIO  BMSW 180" AZ            
N7538IRS1       23 13 45.346 + 61 28 10.32 RJ  -   58.0  9.9   n/a   LSR  RADIO  PS 1200,0 RJ
*
* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
*   SOURCELIST for SPECTRAL LINE FIVEPOINTS
*   Positions taken from Loup et al. A&A Suppl. Ser 99, 291 (1993).
*   This section sub-divided according to positional accuracy flags by Loup et al.
*   except that 
*     - 9 stars with HD numbers and flag=2 that differ by < approx 1"
*       from Hipparcos positions are in section 1.
*     - 6 weak or v.southern objects with Loup flags=1 appear in section 2,
*       since, in the cases where comparison with Hipparcos is possible -
*       the first two - differences of >1" are seen. 
*       (R Hor, R Dor, V1362Aql, V1366Aql, GL2374, GL2885). (20020107)
*   VXSgr & RRAql added 20020107.
*   Note CRL2688 is in section 2 (?!).
*   See also K. Young (1995, ApJ 445, 872). 
*   Other (flux) data often courtesy H. Matthews and J. Greaves.
*   Positions for objects in common with spectral line standards (CRL618,
*   CRL2688, NGC7027, section above) are left unchanged, but these are not
*   inconsistent with Loup.
*   Position for o Ceti updated to J2005.0 - largest p.m. in sample.
*   Note that we still have not gone through all the sources in the list.!! 
*
*   The catalogue gives T_A* (peak) for the 2-1 line. More informative, however, are the integrated line intensities
*   in the comment line (in K km/s), which largely determine how easy it is to detect a line. Note that JCMT 2-1
*   data followed by J are typically low by about a factor of 1.3 - 1.5 (telescope heavily deformed due to conebar
*   welding.
*
*
*               RA & DEC                   Eq  Vlsr     Tpeak  Vrange           JCMT   comments
*- -- -- -- -- -- --  -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
*- -- -- -- -- -- --  -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
* Loup et al position quality flag = 1 (~1")
*
TCas            00 23 14.26  + 55 47 33.9  RJ  -    7.0  1.0   22.0  LSR  RADIO :3-2 12.8  4-3 int 5.5   
WXPsc           01 06 25.96  + 12 35 53.5  RJ  +    8.5  1.4   35.0  LSR  RADIO 2-1 41.0 J3-2 51.2 4-3 23.2 
RScl            01 26 58.07  - 32 32 34.0  RJ  -   18.4  1.5   37.0  LSR  RADIO 2-1 42.3 J 3-2 48.2      
GL230           01 33 51.21  + 62 26 53.5  RJ  -   54.0  0.9   22.0  LSR  RADIO          :IRAM 2-1 16.3  
oCeti           02 19 20.80  - 02 58 34.1  RJ  +   46.5  6.8   28.0  LSR  RADIO 2-1 34.6 J3-2 48.2 4-3 46.2 J2005
UCam            03 41 48.15  + 62 38 55.0  RJ  +    7.1  0.55  64.0  LSR  RADIO 2-1 20.3 J :             
NMLTau          03 53 28.84  + 11 24 22.6  RJ  +   35.1  1.6   43.0  LSR  RADIO 2-1 49.1           4-3 92
CRL618          04 42 53.597 + 36 06 53.65 RJ  -   21.7  3.2   90.0  LSR  RADIO 2-1 118.3 (95) 3-2 95.4 , 4-3
RLep            04 59 36.38  - 14 48 21.6  RJ  +   16.0  0.6   38.0  LSR  RADIO : JCMT 2-1 int 1
NVAur           05 11 19.43  + 52 52 33.7  RJ  +    3.0  0.57  36.0  LSR  RADIO          : OSO 1-0 int 19
RAur            05 17 17.66  + 53 35 10.9  RJ  -    3.0  1.2   20.0  LSR  RADIO : CSO 3-2 16 4-3 11.4
UUAur           06 36 32.84  + 38 26 44.4  RJ  +    7.0  0.6   25.0  LSR  RADIO 2-1 10.5 : IRAM 1-0 15.9 
VYCMa           07 22 58.33  - 25 46 03.2  RJ  +   19.0  1.0   92.0  LSR  RADIO 2-1 50.1                 
M1-16           07 37 18.89  - 09 38 48.5  RJ  +   49.0  0.85  50.0  LSR  RADIO 2-1 48.9 : SEST 2-1 26.0 
M1-17           07 40 22.16  - 11 32 30.1  RJ  +   28.0  1.80  78.0  LSR  RADIO 2-1 31.7 : IRAM 2-1 66.2 
OH231.8         07 42 16.93  - 14 42 50.2  RJ  +   30.0  1.3  160.0  LSR  RADIO 2-1 71.8 : IRAM 1-0 92.5 
RLMi            09 45 34.29  + 34 30 42.8  RJ  +    2.0  0.4   18.0  LSR  RADIO 2-1 5.8  : IRAM 2-1 15.0 
RLeo            09 47 33.49  + 11 25 44.1  RJ  -    0.4  1.0   22.0  LSR  RADIO 2-1 13.0 : CSO 3-2 37 4-3
IRC+10216       09 47 57.382 + 13 16 43.66 RJ  -   25.6 32.    35.0  LSR  RADIO 2-1 427. (564) 3-2 687 (600) 4-3 720
CIT6            10 16 02.27  + 30 34 18.6  RJ  -    1.9  8.5   45.0  LSR  RADIO 2-1 111.3 3-2 194.9 4-3 1
RTVir           13 02 37.95  + 05 11 08.5  RJ  +   18.0  0.7   18.0  LSR  RADIO 2-1 13.5 3-2 12.6 4-3 8.8
WHya            13 49 02.05  - 28 22 02.6  RJ  +   41.3  0.7   20.0  LSR  RADIO 2-1 10.9 3-2 29.0 4-3 21.
RXBoo           14 24 11.61  + 25 42 14.1  RJ  +    1.1  1.4   22.0  LSR  RADIO 2-1 19.3 3-2 32.3 4-3 14.9
SCrB            15 21 23.97  + 31 22 02.8  RJ  +    2.0  0.6   18.0  LSR  RADIO   3-2 5.6 
NGC6302         17 13 44.41  - 37 06 11.2  RJ  -   40.0  2.6   52.0  LSR  RADIO 2-1 73.0 : NRAO 2-1 INT 19.9
V814Her         17 44 55.43  + 50 02 38.4  RJ  -   35.0  0.4   25.0  LSR  RADIO 2-1 5.9  : IRAM 2-1 36.1 
VXSgr           18 08 44.50  - 33 52 00.5  RJ  +    6.0  0.4   60.0  LSR  RADIO 2-1
OH17.7-2        18 30 30.64  - 14 28 57.0  RJ  +   62.0  0.3   25.0  LSR  RADIO   3-2 5.0 HEM IRAM 2-1 19.4
V437Sct         18 37 32.46  - 05 23 59.4  RJ  +   29.0  1.41  23.0  LSR  RADIO :3-2 13.9                
V1111Oph        18 37 19.31  + 10 25 42.4  RJ  -   30.0  0.8   40.0  LSR  RADIO 2-1 23.4 : OSO 1-0 29.4  
V1365Aql        18 52 22.19  - 00 14 13.9  RJ  +   63.0  1.4   28.0  LSR  RADIO 2-1 11.5 : IRAM 2-1 14.0,
RAql            19 06 22.18  + 08 13 49.1  RJ  +   46.0  1.1   20.0  LSR  RADIO 2-1 15.5 : CSO 3-2  45 4-3 int 36.9
HD179821        19 13 58.53  + 00 07 31.6  RJ  +  100.0  1.1   76.0  LSR  RADIO     3-2 57.5 HEM         
GL2374          19 21 36.52  + 09 27 56.5  RJ  -   72.0  1.4   33.0  LSR  RADIO          : IRAM 2-1 int 2
V1302Aql        19 26 48.03  + 11 21 16.7  RJ  +   73.0  1.0   90.0  LSR  RADIO 2-1 57.0 3-2 114.7 4-3 101.5 
GYAql           19 50 06.35  - 07 36 52.8  RJ  +   34.0  1.08  23.0  LSR  RADIO 2-1 24.4 : NRAO 2-1      
KiCyg           19 50 33.95  + 32 54 51.2  RJ  +   10.0  3.5   21.0  LSR  RADIO  3-2 58.9 4-3 70.2       
RRAql           19 57 36.03  - 01 53 10.4  RJ  +   28.0  0.5   15.0  LSR  RADIO 2-1
VCyg            20 41 18.30  + 48 08 29.1  RJ  +   14.0  3.9   30.0  LSR  RADIO  3-2 62.9 4-3 71.0       
NMLCyg          20 46 25.46  + 40 06 59.6  RJ  +    1.0  2.0   65.0  LSR  RADIO  3-2 85.9 HEM 4-3 96.5 
NGC7027         21 07 01.593 + 42 14 10.18 RJ  +   26.0  8.5   50.0  LSR  RADIO 2-1 192.9 J 219.6(290) 3-2(280) 4-3(238.0)
SCep            21 35 12.60  + 78 37 28.4  RJ  -   16.0  1.6   63.0  LSR  RADIO 2-1 40.9 3-2 50.4/38.3 IRAM 2-1 60
RCas            23 58 24.76  + 51 23 19.5  RJ  +   25.0  1.6   31.0  LSR  RADIO 2-1 29.0 J 3-2 73.5 4-3 47.6 NL
*
* Loup et al position quality flag = 2 (~1"-5")
*
RAnd            00 24 01.99  + 38 34 40.0  RJ  -   16.0  1.1   22.0  LSR  RADIO 2-1 14.5 J               
GL67            00 27 41.15  + 69 38 51.7  RJ  -   28.6  1.5   43.0  LSR  RADIO 2-1 32.7 :               
IRC+60041       01 13 44.31  + 62 57 36.0  RJ  -   25.0  0.1   47.0  LSR  RADIO          : NRAO 2-1      
RHor            02 53 52.46  - 49 53 23.8  RJ  +   38.0  0.8   13.0  LSR  RADIO 2-1
V384Per         03 26 29.53  + 47 31 50.2  RJ  -   16.3  1.3   33.0  LSR  RADIO 2-1 28.1  OSO 1-0 25.0
IRC+60144       04 35 17.45  + 62 16 23.3  RJ  -   45.0  0.8   30.0  LSR  RADIO          : OSO 1-0 int 18.7
RDor            04 36 45.84  - 62 04 35.7  RJ  +    7.0  2.5   13.0  LSR  RADIO 2-1
V370Aur         05 43 49.78  + 32 42 06.8  RJ  -   31.0  0.65  52.0  LSR  RADIO : NRAO 2-1      
GL865           06 03 59.84  + 07 25 54.4  RJ  +   42.5  1.8   33.0  LSR  RADIO 2-1 36.0 : OSO 1-0 17.0  
V636Mon         06 25 01.37  - 09 07 16.0  RJ  +   13.0  0.39  50.0  LSR  RADIO 2-1 21.5 : JCMT 2-1 12.4 ?? from lit.
APLyn           06 34 33.92  + 60 56 26.2  RJ  -   23.0  0.49  35.0  LSR  RADIO : OSO 1-0 13.0  
M1-7            06 37 20.95  + 24 00 31.0  RJ  -   11.0  0.46  50.0  LSR  RADIO 2-1 44.1 : NRAO 2-1 17.1 
GMCMa           06 41 15.00  - 22 16 42.9  RJ  +   48.0  0.5   40.0  LSR  RADIO 2-1 11.0 : IRAM 2-1 29.0 
GXMon           06 52 46.91  + 08 25 19.0  RJ  -    7.0  1.7   40.0  LSR  RADIO 2-1 48.0 : OSO 1-0 30.5  
HD56126         07 16 10.23  + 09 59 47.9  RJ  +   73.0  2.0   24.0  LSR  RADIO 2-1 23.1 3-2 22.4        
GL5254          09 13 54.09  - 24 51 21.1  RJ  +    0.1  3.5   32.0  LSR  RADIO 2-1 55.3 3-2 49.6
VHya            10 51 37.31  - 21 15 01.3  RJ  -   15.6  5.0   52.0  LSR  RADIO 2-1 73.7 3-2 97.8        
XHer            16 02 39.39  + 47 14 22.3  RJ  -   73.0  1.3   23.0  LSR  RADIO 2-1 12.0                 
GL1922          17 07 58.24  - 24 44 31.1  RJ  -    3.0  1.73  40.0  LSR  RADIO 2-1 45.0 3-2 56.3        
GL2135          18 22 34.50  - 27 06 30.2  RJ  +   48.0  1.31  45.0  LSR  RADIO 2-1 45.8 3-2 59.7
GL2143          18 24 31.84  - 16 16 04.2  RJ  -   27.0  0.9   34.0  LSR  RADIO          : IRAM 2-1 19.4 
GL2199          18 35 46.48  + 05 35 46.5  RJ  +   30.0  0.67  40.0  LSR  RADIO          : OSO 1-0 16.7  
V821Her         18 41 54.39  + 17 41 08.5  RJ  +    0.0  2.0   31.0  LSR  RADIO 2-1 39.6 3-2 54.5 IRAM 2-1 93.9
IRC+00365       18 42 24.68  - 02 17 25.2  RJ  +    3.0  0.7   73.0  LSR  RADIO 2-1 35.3 3-2 57.7
RSct            18 47 29.00  - 05 42 14.6  RJ  +   56.0  0.8   10.0  LSR  RADIO 2-1 4.2  : IRAM 2-1 11.0 
V1362Aql        18 48 41.91  - 02 50 28.3  RJ  +  101.0  1.1   35.0  LSR  RADIO 2-1
V1366Aql        18 58 30.02  + 06 42 57.7  RJ  +   21.0  0.6   31.0  LSR  RADIO 2-1
GL2316          19 05 22.69  + 08 13 05.0  RJ  +    2.0  1.0   34.0  LSR  RADIO          : IRAM 2-1 23.3 
WAql            19 15 23.21  - 07 02 49.8  RJ  -   25.0  0.8   42.0  LSR  RADIO          : CSO 2-1 int 22
IRC-10502       19 20 17.96  - 08 02 10.6  RJ  +   21.0  0.67  57.0  LSR  RADIO 2-1 27.9 JG 3-2 40.0     
OH44.8          19 21 36.52  + 09 27 56.5  RJ  -   72.0  0.5   30.0  LSR  RADIO 2-1
V1965Cyg        19 34 09.87  + 28 04 06.3  RJ  -   12.0  0.77  54.0  LSR  RADIO :3-2 44.8                
HD187885        19 52 52.64  - 17 01 50.1  RJ  +   24.0  0.7   75.0  LSR  RADIO 2-1 12.6   3-2 25.8      
CRL2688         21 02 18.805 + 36 41 37.70 RJ  -   35.4  5.0   80.0  LSR  RADIO 2-1 120 J (190), 3-2 (197
OH104.9         22 19 27.40  + 59 51 22.7  RJ  -   27.0  0.5   34.0  LSR  RADIO 2-1
Pi1Gru          22 22 43.81  - 45 56 50.4  RJ  -   12.0  2.1   40.0  LSR  RADIO  3-2 74.3 4-3 38.8 NL    
HD235858        22 29 10.29  + 54 51 06.6  RJ  -   28.0  2.1   22.0  LSR  RADIO  3-2 34.5 also CS 7-6    
LPAnd           23 34 27.66  + 43 33 02.4  RJ  -   17.0  2.7   29.0  LSR  RADIO 2-1 52.8 J 3-2 70.0 4-3 3
*
* Loup et al position quality flag = 3 (?>5")
*
01142+6306      01 17 33.31  + 63 22 05.8  RJ  -   20.0  0.7   38.0  LSR  RADIO 2-1 28.3 :IRAM 2-1 11.0  
GL190           01 17 51.62  + 67 13 55.4  RJ  -   39.0  3.1   37.0  LSR  RADIO          :IRAM 2-1 70.   
GL482           03 23 36.57  + 70 27 07.5  RJ  -   16.4  0.9   20.0  LSR  RADIO 2-1 11.3 J : OSO 1-0 9.00
03313+6058      03 35 30.69  + 61 08 47.2  RJ  -   39.0  0.6   30.0  LSR  RADIO          : IRAM 2-1 13.2 
GL5102          03 48 18.01  + 44 42 02.1  RJ  -   25.0  0.4   32.0  LSR  RADIO          : OSO 1-0 int 11 
TXCam           05 00 50.39  + 56 10 52.6  RJ  +    9.2  2.9   50.0  LSR  RADIO 2-1 75.8 : IRAM 2-1 108  
BXCam           05 46 44.10  + 69 58 25.2  RJ  +    0.0  0.54  45.0  LSR  RADIO          : OSO 1-0 15.4  
GL1235          08 10 48.40  - 32 52 03.9  RJ  -   20.3  0.9   42.0  LSR  RADIO 2-1 29.0 3-2 37.5 
CRL4211         15 11 41.89  - 48 20 01.3  RJ  -    3.7  2.5   42.0  LSR  RADIO 2-1 72.6 
IRC+20326       17 31 54.98  + 17 45 19.7  RJ  -    4.0  1.5   34.0  LSR  RADIO 2-1 31.3 : OSO 1-0 int 20
GL5379          17 44 22.62  - 31 55 39.4  RJ  -   20.5  2.8   43.0  LSR  RADIO 2-1 31.8  3-2 59.7: 
GL2155          18 26 05.69  + 23 28 50.3  RJ  +   60.0  1.12  34.0  LSR  RADIO          : OSO 1-0  23.2 
19454+2920      19 47 24.25  + 29 28 11.8  RJ  +   21.0  0.73  29.0  LSR  RADIO          : IRAM 2-1 int 14.3
GL2477          19 56 48.26  + 30 43 59.2  RJ  +    5.0  1.7   50.0  LSR  RADIO  3-2 26.6                
GL2494          20 01 08.51  + 40 55 40.2  RJ  +   30.0  1.3   48.0  LSR  RADIO 2-1 38.2 3-2 53.5 4-3 49 
V1300Aql        20 10 27.41  - 06 16 15.7  RJ  -   18.0  1.2   34.0  LSR  RADIO 2-1 37.0 3-2 40.4 4-3 33.7
OH63.3-10.2     20 28 56.84  + 21 15 34.6  RJ  -   72.0  0.76  37.0  LSR  RADIO          : IRAM 2-1 int 1
GL2686          20 59 08.88  + 27 26 41.7  RJ  +    1.0  0.32  48.0  LSR  RADIO 2-1 28.7 
21282+5050      21 29 58.42  + 51 03 59.8  RJ  +   18.0  4.2   37.0  LSR  RADIO  3-2 74 IRAM 2-1 int 279 
21318+5631      21 33 22.98  + 56 44 35.0  RJ  +    0.0  0.95  37.0  LSR  RADIO  3-2 19.7                
21554+6204      21 56 58.18  + 62 18 43.6  RJ  -   17.0  0.75  37.0  LSR  RADIO 2-1 10.9 : IRAM 2-1 int 1
GL3068          23 19 12.39  + 17 11 35.4  RJ  -   31.0  6.1   31.0  LSR  RADIO  3-2 49.6 4-3 37.4 
23304+6147      23 32 44.94  + 62 03 49.6  RJ  -   17.0  0.4   31.0  LSR  RADIO   3-2 6.7 HEM IRAM 2-1 int 25.0
23321+6545      23 34 22.63  + 66 01 50.4  RJ  -   56.0  0.24  40.0  LSR  RADIO   3-2 6.2 HEM IRAM 2-1 int 28
*
* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
*   OBSERVATORY BAD WEATHER BACKUP; CO and ISOTOPES for all sources (BW = 125 MHz)
*   except NGC7538IRS1, which is observed at 241.8 GHz LSB and with DAS 500MHz Bandwidth 
*   DETAILS AND CURRENT STATUS IS FOUND IN THE OBSERVATORY BACKUP FOLDER
*
*               RA & DEC                       Vlsr     Tpeak  Vrange   comments
* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
HORSEHEAD       05 40 58.765 - 02 27 36.41 RJ  +   10.5 28.0   n/a   LSR  RADIO  PS -800,0 RJ ; peak at (-80",+40")
N2023mm1        05 41 24.778 - 02 18 09.19 RJ  +   10.5 25.0   n/a   LSR  RADIO                          
16293E          16 32 28.842 - 24 28 57.60 RJ  +    4.0 11.0   n/a   LSR  RADIO  PS -800,0 RJ
N7538IRS1       23 13 45.346 + 61 28 10.32 RJ  -   58.0  9.5   n/a   LSR  RADIO  PS -100,100 ; use cell 10",10" RJ
*
* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
*
*
*           MISCELLANEOUS SOURCES
*
* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
HOLO            92 55 08.0   + 08 35 07.00 AZ    n/a     n/a   n/a   LSR  RADIO  Position for holography
*
* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
