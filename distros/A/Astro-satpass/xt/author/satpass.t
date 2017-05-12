package main;

use strict;
use warnings;

use lib qw{ inc };

use My::Module::Satpass;

eval {
    require Astro::SpaceTrack;
    Astro::SpaceTrack->VERSION( 0.052 );
    1;
}
    or do {
    print "1..0 # skip Astro::SpaceTrack version 0.052 or above not available\n";
    exit;
};

My::Module::Satpass::satpass( *DATA );

1;
__END__

st get direct
-data st set direct 0
-test st get direct

st set direct 1
st get direct
-data st set direct 1
-test st set direct 1

-skip ''

set horizon 10
show horizon
-data set horizon 10
-test set horizon 10

macro
-data
-test macro listing (should be empty)

macro foo 'set horizon 20'
macro
-data macro foo 'set horizon 20'
-test macro definition

foo
show horizon
-data set horizon 20
-test macro 'foo' execution

macro foo 'localize horizon' 'set horizon 10' 'show horizon'
-data <<eod
macro foo 'localize horizon' \
    'set horizon 10' \
    'show horizon'
eod
macro
-test macro 'foo' redefinition

foo
-data set horizon 10
-test redefined macro 'foo' execution

show horizon
-data set horizon 20
-test localization of horizon

-skip $^O ne 'darwin' ? "Not running darwin" : -e '/usr/bin/pbcopy' ? '' : "Can not find /usr/bin/pbcopy"

set horizon 30
show horizon -clipboard
-result $^O eq 'darwin' ? `pbpaste` : ''
-data set horizon 30
-test redirect to clipboard (Mac OS X only)

-skip ''

set horizon 15
-unlink test.tmp
show horizon >test.tmp
-data set horizon 15
-read test.tmp
-test redirect to file

-data <<eod
set location '1600 Pennsylvania Ave NW Washington DC 20502'
set latitude 38.898748
set longitude -77.037684
set height 16.68
eod
-write test.tmp
source test.tmp
show location latitude longitude height
-test source file

foo >test.tmp
-read test.tmp
-data set horizon 10
-test redirect macro output to file

-unlink test.tmp

set explicit_macro_delete 0
macro foo
macro
-data
-test macro deletion

foo
-data Error - Verb 'foo' not recognized.
-test make sure macro can not be executed

macro foo 'set horizon 17'
set explicit_macro_delete 1
macro foo
-data macro foo 'set horizon 17'
-test explicit_macro_delete turned on

macro -delete foo
macro
-data
-test explicit macro deletion via -delete

-skip <<eod
-d 'fubar' ? 'Directory fubar exists' :
-e 'fubar' ? 'File fubar exists but is not a directory' : ''
eod

cd fubar
-data <<eod
Error - Can not cd to fubar
        No such file or directory
eod
-test change directory (bad directory name)

-home
-skip (-d 't') ? '' : 'Directory t does not exist'
cd t
-result ($home eq getcwd) ? 'Failed to change directory' : 'Changed directory to t'
-data Changed directory to t
-test change directory

-home
-skip ''

set tz GMT
set date_format '%Y-%m-%d'
almanac '2006-07-01 00:00:00'
-data <<eod
Location: 1600 Pennsylvania Ave NW Washington DC 20502
          Latitude 38.8987, longitude -77.0377, height 17 m
2006-07-01
00:37:32 Sunset
01:09:26 End civil twilight (-6 degrees)
03:54:04 Moon set
05:11:56 Local midnight
09:14:33 Begin civil twilight (-6 degrees)
09:46:27 Sunrise
15:26:28 Moon rise
17:12:02 Local noon
21:55:25 Moon transits meridian
eod
-test almanac function

set horizon 0
macro foo 'set horizon $1'
foo 10
show horizon
-data set horizon 10
-test macro parameter passing

macro foo 'set horizon "${1:-20}"'
foo
show horizon
-data set horizon 20
-test macro parameter defaulting

macro foo 'set horizon "${1:?You must supply a value}"'
foo
-data You must supply a value
-test macro missing paramater message

macro foo 'local twilight' 'set twilight ${1:=30}' 'set horizon $1'
foo
show horizon
-data set horizon 30
-test macro parameter defaulting (sticky)

macro foo 'set horizon ${1:+40}'
foo 20
show horizon
-data set horizon 40
-test macro parameter overriding
