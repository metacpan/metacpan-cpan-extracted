#!perl

use Test::More;
plan skip_all => 'POD tests are only run in RELEASE_TESTING mode.' unless $ENV{'RELEASE_TESTING'};

eval 'use Test::Spelling 0.19';
plan skip_all => 'Test::Spelling v0.19 required for testing POD' if $@;

add_stopwords( map { split /[\s\:\-]/ } readline(*DATA) );
$ENV{LANG} = 'C';
all_pod_files_spelling_ok();

__DATA__
MERCHANTABILITY
Muey

LICENCE
Façade
app
-no-try
UTC
UTF-8
TODO
façade
et al

CRLF

cPanel

Pangea

'base'

nadda

txt

appkit

ctype

'rwp'
ENV
refactor
ick
multiton
readonly
readwrite

'inc'
bindir

'database'
'host'
'pass'
'user'
DSN
SQLite
datetime
dbh
utf

conf
param
params

JSON
YAML

'log
YYYY
conf'
emerg

DBI

'use
