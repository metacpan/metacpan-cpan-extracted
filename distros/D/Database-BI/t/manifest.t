#!perl -w

# Author test: MANIFEST must list every file that is in the distribution, and
# nothing that is not.  This is the check that catches the classic packaging
# defect: a new module or template the test suite loads from the working
# directory, which would be absent for everyone installing from the tarball.
#
# Test::CheckManifest honours MANIFEST.SKIP, so build products (blib,
# MYMETA.*, the tarball) and the author's own notes (BI-*.md, CLAUDE.md) are
# excluded by the same rules `make dist` uses.  Skips without
# Test::CheckManifest, and does not run unless AUTHOR_TESTING is set.
#
#   AUTHOR_TESTING=1 prove -l t/manifest.t

use strict;
use warnings;

use Test::DescribeMe qw(author);
use Test::Most;
use Test::Needs { 'Test::CheckManifest' => '0.9' };

Test::CheckManifest->import();
ok_manifest({ filter => [qr/(\.git)|(\..+\.yml$)/] });
