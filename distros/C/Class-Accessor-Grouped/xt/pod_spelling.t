use strict;
use warnings;
use Test::More;
BEGIN {
  eval 'use Test::Spelling 0.11; 1'
    or plan skip_all => 'Test::Spelling 0.11 not installed';
}

set_spell_cmd('aspell list');

add_stopwords(<DATA>);

all_pod_files_spelling_ok();

__DATA__
Bowden
Raygun
Roditi
isa
mst
behaviour
further
overridable
Laco
Pauley
claco
stylings
fieldspec
listref
getters
ribasushi
Rabbitson
groditi
Caelum
Kitover
CAF
Sep
XSA
OTRW
runtime
Axel
fREW
frew
getter
subclasses
Benchmarking
