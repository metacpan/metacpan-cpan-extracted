#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

unless ($ENV{RELEASE_TESTING}) {
  plan( skip_all => 'these tests are for release candidate testing' );
}

eval "use Test::CheckManifest 0.9";    ## no critic (eval)
plan skip_all => "Test::CheckManifest 0.9 required" if $@;
ok_manifest( {
  exclude => [qw(/.git /.gitignore /.travis.yml /Makefile.old)],
  filter => [qr/\.swp$/, qr/.tar.gz$/],
} );
