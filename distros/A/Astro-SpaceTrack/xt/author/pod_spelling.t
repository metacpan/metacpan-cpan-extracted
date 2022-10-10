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
CATNR
celestrak
checkbox
checksums
China's
co
com
cpan
dataset
designator
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
glonass
gnupg
GoDaddy
GPG
hoc
HTTPS
IDs
inmarsat
INTDES
intelsat
ISP
ISS
JSON
kelso
keyring
login
mccants
McCants
merchantability
metacpan
multimonth
NAVSTAR
nnn
NORAD
OID
OIDs
olist
onorbit
Optionmenu
orbcomm
org
pre
redirections
redistributer
redistributers
RCS
rms
SATCAT
sladen
spaceflight
spacetrack
SpaceTrackTk
SSL
STDERR
STDOUT
sts
tle
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
yyyy
ZZZ
