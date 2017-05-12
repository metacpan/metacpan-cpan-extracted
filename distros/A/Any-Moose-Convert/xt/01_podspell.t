#!perl -w

use strict;
use Test::More;

eval q{ use Test::Spelling };

plan skip_all => q{Test::Spelling is not installed.}
	if $@;

add_stopwords(map { split /[\s\:\-]/ } <DATA>);
$ENV{LANG} = 'C';
all_pod_files_spelling_ok('lib');

__DATA__
gfx
Goro Fuji (gfx)
gfuji(at)cpan.org
Any::Moose::Convert
versa
