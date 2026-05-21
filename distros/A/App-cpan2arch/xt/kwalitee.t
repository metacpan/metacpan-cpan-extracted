#!perl

use v5.42.0;

use strict;
use warnings;

use Test2::V1              qw< diag >;
use Test2::Require::Module qw< Test::Kwalitee >;

use Test::Kwalitee qw< kwalitee_ok >;

diag <<'END';
NOTE:
  This test must be done in the unpacked release tarball directory, which
  misses some kwalitee indicators.

  For a more complete test, install App::CPANTS::Lint and run it on the
  release tarball:

    $ cpanm App::CPANTS::Lint
    $ cpants_lint.pl --color --verbose App-cpan2arch-v1.0.0.tar.gz

END

kwalitee_ok();
T2->done_testing;
