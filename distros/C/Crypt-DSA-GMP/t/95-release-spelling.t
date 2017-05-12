#!/usr/bin/env perl
use strict;
use warnings;

BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for release candidate testing');
  }
}

#---------------------------------------------------------------------


use Test::More;
eval "use Test::Spellunker";   ## no critic (eval)
plan skip_all => "Test::Spellunker required for testing POD spelling" if $@;

add_stopwords(qw/ OpenSSL OpenSSH keygen passphrase QSize leftmost superset /);

all_pod_files_spelling_ok();
