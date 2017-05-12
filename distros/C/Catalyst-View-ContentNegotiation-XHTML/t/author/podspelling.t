#!perl -w
use strict;
use warnings;
use Test::More;

use Test::Spelling 0.11;

set_spell_cmd('aspell list');

add_stopwords( grep { defined $_ && length $_ } <DATA>);

all_pod_files_spelling_ok();

__DATA__
XHTML
TT
Doran
Dorward
rafl
ContentNegotiation
Ragwitz
firefox
