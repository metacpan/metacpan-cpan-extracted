#!perl -w

use strict;
use warnings;
use Test::Spelling;
use utf8;

add_stopwords(map { split /[\s\:\-]/ } <DATA>);
$ENV{LANG} = 'C';
all_pod_files_spelling_ok('lib');

__DATA__
API
CPAN
Coro
Grünauer
Marcel
OO
ShipIt
YAML
behaviour
blogs
chomps
distname
github
init
op
pipe's
placeholders
redispatch
ref
segment's
shipit
tokenizes
unshifts
username
whitelist
whitelists
yml
