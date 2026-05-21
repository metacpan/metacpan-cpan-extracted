#!perl

use v5.42.0;

use strict;
use warnings;

use Test2::V1              qw< diag >;
use Test2::Require::Module qw< Test::Spelling >;

use Test::Spelling;
use Pod::Wordlist;

diag <<'END';
NOTE:
  This test requires a spellchecker with an English dictionary installed, e.g. aspell.

END

add_stopwords(<DATA>);

all_pod_files_spelling_ok(
    qw<
        bin
        script
        lib
    >
);

__DATA__
ryoskzypu
