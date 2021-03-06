#!perl

BEGIN {
    unless ( $ENV{RELEASE_TESTING} ) {
        require Test::More;
        Test::More::plan(
            skip_all => 'these tests are for release candidate testing' );
    }
}

use Test::More;

eval 'use Test::Mojibake';
plan skip_all => 'Test::Mojibake required for source encoding testing'
  if $@;

all_files_encoding_ok();
