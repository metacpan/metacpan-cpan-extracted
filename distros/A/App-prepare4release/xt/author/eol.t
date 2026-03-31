#!perl
use strict;
use warnings;
use Test2::V1;
use Test2::Tools::Basic qw(skip_all done_testing);

BEGIN {
	eval {
		require Test::EOL;
		Test::EOL->import;
		1;
	} or skip_all 'Test::EOL is required for author tests';
}

my @files = qw(
    Makefile.PL
    lib/App/prepare4release.pm
    bin/prepare4release
    t/00-load.t
    t/alien-scan.t
    t/ci-ensure.t
    t/ci-render.t
    t/config-load.t
    t/perl-matrix.t
    t/pm-min-version.t
    xt/metacpan-live.t
    xt/author/compile-internal.t
    xt/author/compile.t
    xt/author/cpants.t
    xt/author/dependent-modules.t
    xt/author/eol.t
    xt/author/kwalitee.t
    xt/author/minimum-version.t
    xt/author/pause-permissions.t
    xt/author/pod-coverage.t
    xt/author/pod.t
    xt/author/portability.t
    xt/author/synopsis.t
    xt/author/version.t
);

eol_unix_ok($_) for @files;

done_testing;
