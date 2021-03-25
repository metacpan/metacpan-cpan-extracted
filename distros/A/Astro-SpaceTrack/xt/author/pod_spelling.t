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
amsat
antisatellite
API
attrib
celestrak
Celestrak
Celestrak's
checkbox
checksums
China's
co
com
cpan
dataset
decrypt
Designator
ephemeris
executables
EXECUTABLES
exportable
fallback
Fengyun
filename
globalstar
Globalstar
glonass
GLONASS
gnupg
GoDaddy
GPG
hoc
HTTPS
IDs
inmarsat
Inmarsat
intelsat
ISP
ISS
JSON
kelso
Kelso
Kelso's
keyring
login
mccants
McCants
merchantability
metacpan
multimonth
NAVSTAR
NORAD
OID
OIDs
olist
onorbit
Optionmenu
orbcomm
OrbComm
org
pre
redirections
Redirections
redistributer
redistributers
RCS
RMS
SATCAT
sladen
Sladen
Sladen's
spaceflight
spacetrack
SpaceTrack
SpaceTrackTk
SSL
STDERR
STDOUT
sts
tle
TLE
TLEs
txt
un
unzip
unzipped
URI
usa
username
Vesselsats
VMS
webcmd
Westford
www
Wyant
xxx
ZZZ
