#!perl

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}


use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Perl::Critic::Subset 3.001.003

use Test::Perl::Critic (-profile => "") x!! -e "";

my $filenames = ['lib/App/SahUtils.pm','script/coerce-with-sah','script/format-with-sah','script/get-sah-type','script/is-sah-builtin-type','script/is-sah-collection-builtin-type','script/is-sah-collection-type','script/is-sah-numeric-builtin-type','script/is-sah-numeric-type','script/is-sah-ref-builtin-type','script/is-sah-ref-type','script/is-sah-simple-builtin-type','script/is-sah-simple-type','script/is-sah-type','script/list-sah-clauses','script/list-sah-coerce-rule-modules','script/list-sah-schema-modules','script/list-sah-schemas-modules','script/list-sah-type-modules','script/normalize-sah-schema','script/resolve-sah-schema','script/sah-to-human','script/show-sah-coerce-rule-module','script/show-sah-schema-module','script/validate-with-sah'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
