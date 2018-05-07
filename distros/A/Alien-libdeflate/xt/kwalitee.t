## -*- mode: perl; -*-
use strict;
use warnings;
use Test::More;

BEGIN {
    plan skip_all => 'only for release testing purposes (RELEASE_TESTING=1)'
        unless $ENV{RELEASE_TESTING};
}

subtest kwalitee => sub {
  eval 'use Test::Kwalitee qw{kwalitee_ok}; 1';

  diag "Test::Kwalitee is required" if $@;

  plan skip_all => "cpanm --installdeps --with-feature=release -n -q ." if $@;

  kwalitee_ok(qw{
    -use_strict
    -no_symlinks
    -has_human_readable_license
    -has_license_in_source_file
  });
};

done_testing;
