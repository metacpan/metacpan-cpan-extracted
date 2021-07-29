package main;

use strict;
use warnings;

use utf8;

use open qw{ :std :encoding(utf-8) };

BEGIN {
    eval {
	require Test::Spelling;
	1;
    } or do {
	print "1..0 # skip Test::Spelling not available.\n";
	exit;
    };
    Test::Spelling->import();
}

# The following is a hack. It looks like things work the way I want if I
# pass encoded UTF-8 around, rather than actual characters.

binmode DATA;

add_stopwords( <DATA> );

all_pod_files_spelling_ok();

1;

__DATA__
AlmanacConfigFile
ano
año
calc
ConfigFile
dmd
geolocation
mediodia
merchantability
si
sí
Wyant
