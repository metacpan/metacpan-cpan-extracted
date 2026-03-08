#!/usr/bin/env perl

use Test::More;

BEGIN {
    eval "use Test::Spelling::Stopwords";
    if ($@) {
        plan skip_all => "Test::Spelling::Stopwords required for testing POD spelling";
    }
}

unless ($ENV{AUTHOR_TESTING} || $ENV{RELEASE_TESTING} || $ENV{CI}) {
    plan skip_all => 'Spelling tests only run under AUTHOR_TESTING';
}

all_pod_files_spelling_ok();
