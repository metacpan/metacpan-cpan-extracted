package main;

use strict;
use warnings;

BEGIN {
    eval {
	require Test::Spelling;
	Test::Spelling->import();
	1;
    } or do {
	print "1..0 # skip Test::Spelling not available.\n";
	exit;
    };
}

add_stopwords (<DATA>);

all_pod_files_spelling_ok ();

1;
__DATA__
Above's
accreted
akm
Alasdair
altazimuth
AMSAT
angulardiameter
angularvelocity
apoapsis
App
appulse
appulsed
appulsing
appulses
argumentofperigee
ascendingnode
ascensional
Astro
astrodynamics
astrometry
au
autoheight
azel
azimuthal
backdate
Barycentric
barycentre
BC
bissextile
body's
boosters
Borkowski
Borkowski's
Brett
Brodowski
bstardrag
CA
ca
CalSky
CelesTrak
Chalpront
cmd
Coord
coodinate
Coords
CPAN
dans
darwin
dataset
datetime
de
deb
declinational
deg
degreesDminutesMsecondsS
des
designator
distsq
DMOD
Dominik
Drexel
ds
du
dualvar
dualvars
durations
ECEF
ECI
eci
EDT
edt
edu
elementnumber
elevational
ELP
ephemerides
ephemeris
ephemeristype
Escobal
EST
et
exportable
extrema
ff
filename
firstderivative
foo
formatter
Foucault
fr
Francou
Fugina
Gasparovic
gb
geocode
Geocoder
geocoder
geodesy
gmt
gmtime's
Goran
gory
Green's
Gregorian
harvard
haversine
haversines
hoc
http
Hujsak
IDL
IDs
illum
illuminator
IMACAT
Imacat
ini
invocant
invocant's
internet
isa
jan
jcent
jd
jday
Jenness
JSON
jul
julianday
Kazimierz
Kelso
Kelso's
lib
libnova
LLC
localizations
login
lookup
lookups
ls
Lune
ly
magics
Magliacane
Magliacane's
Maidenhead
magma
Mariana
max
McCants
meananomaly
meanmotion
Meeus
merchantability
min
mish
mixin
mma
mmas
Molczan
Moon's
MoonPhase
MSWin
Mueller
namespace
nd
NORAD
NORAD's
nouvelles
nutation
obliquity
Observatoire
OID
OIDs
op
oped
orbitaux
orizuru
Ouachita
Palau
params
parametres
pbcopy
pbpaste
pc
PE
periapsis
perigee
perltime
Persei
pg
photosphere
pkm
pm
pp
pre
precess
precessed
precesses
precession
precisions
psiprime
Puerto
Quicksat
rad
radian
radians
Ramon
rcs
readonly
rebless
reblessable
reblessed
reblesses
reblessing
recessional
ref
reportable
revolutionsatepoch
Rico
rightascension
Roehric
ruggedizing
Saemundsson
SATCAT
Satpass
satpass
SATPASSINI
SDP
sdp
secondderivative
semimajor
semiminor
SGP
sgp
SI
SIGINT
SIMBAD
Simbad
simbad
Sinnott
SKYSAT
skysat
SLALIB
Smart's
solstices
SPACETRACK
Spacetrack
specular
Starlink
STDERR
Steele's
Steffen
Stellarium
Storable
strasbg
subclasses
subcommand
subcommands
SunTime
Survey's
TAI
TDB
TDT
Terre
thetag
Thorfinn
Thorfinn's
timegm's
timekeeping
TIMEZONES
TLE
tle
TLEs
TT
Touze
Turbo
TWOPI
tz
uk
unreduced
URI
username
USGS
USSTRATCOM
UT
UTC
VA
valeurs
Vallado
ver
versa
VMS
Wayback
webcmd
westford
WGS
Willmann
Wyant
xclip
xxxx
XYZ
