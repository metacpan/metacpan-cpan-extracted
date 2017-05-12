#!perl -w

use strict;
use Test::More;

eval q{ use Test::Spellunker };

plan skip_all => q{Test::Spellunker is not installed.}
	if $@;

add_stopwords(map { /(\w+)/g } <DATA>);
all_pod_files_spelling_ok('lib');

__DATA__
Goro Fuji (gfx)
gfuji(at)cpan.org
Acme::Hidek
hidek
APIs
RT
