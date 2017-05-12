#!perl

# Test STL format read

# Astro::Catalog test harness
use Test::More tests => 4;

# strict
use strict;

#load test
use File::Spec;
use Data::Dumper;

# load modules
require_ok("Astro::Catalog");

my $cat = new Astro::Catalog( Format => 'STL', Data => \*DATA );

isa_ok( $cat, "Astro::Catalog" );

my $star = $cat->popstar();
my $id = $star->id;

is( $id, "4", "STL Star ID" );

my $ra = $star->ra;

is( $ra, "05 17 36.30", "STL Star RA" );

exit;

# D A T A   B L O C K --------------------------------------------------------

__DATA__
!+
! Simple STL example; stellar photometry catalogue.
!
! A.C. Davenhall (Edinburgh) 24/1/97.
!-

C PIDENT   INTEGER   1     EXFMT=I6
:    COMMENTS='Position identifier'
C RA   DOUBLE  2  UNITS='RADIANS{HOURS}'
:    TBLFMT=HOURS
C DEC  DOUBLE  3  UNITS='RADIANS{DEGREES}'  TBLFMT=DEGREES

P EQUINOX  CHAR*10  'J2000.0'
P EPOCH    CHAR*10  'J1996.35'

BEGINTABLE
1   5:09:08.7   -8:45:15
2   5:07:50.9   -5:05:11
3   5:01:26.3   -7:10:26
4   5:17:36.3   -6:50:40
