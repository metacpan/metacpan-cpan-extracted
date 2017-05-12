#!perl

use strict;
use warnings;
use Test::More;

eval q{ use Test::Spelling };

plan skip_all => q{Test::Spelling is not installed.}
  if $@;

add_stopwords( map { /(\w+)/g } <DATA> );
$ENV{LANG} = 'C';
all_pod_files_spelling_ok('lib');

__DATA__
MERCHANTABILITY
moznion
