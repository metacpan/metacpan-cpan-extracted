#!perl
use strict;
use warnings;
use lib 'lib', 't/lib';
use Feature::Compat::Defer;
use builtin 'trim';
no warnings 'experimental::builtin';

use List::Util 1.33 'any';
use Path::Tiny 0.119;
use Test::More;
use TestArchiveSCS;

# General commands

like scs_archive(),
  qr{Usage:}, 'usage';

like scs_archive(qw[ --version ]),
  qr{Archive::SCS version}, 'version';

my @help = scs_archive(qw[ --help ]);
ok @help > 60 && ( any { 'OPTIONS' eq trim $_ } @help ), 'help';

like scs_archive(qw[ --foobar ]),
  qr{Unknown option: foobar.*Usage:}s, 'unknown option';

# Read from single archive file to stdout

my $tempdir = Path::Tiny->tempdir('Archive-SCS-test-XXXXXX');
defer { $tempdir->remove_tree; }

my $file = "$tempdir/sample1.scs";
create_hashfs1 $file, sample1;

is_deeply [scs_archive(qw[ --list-files --mount ], $file)],
  [qw(
    dir/subdir/SubDirFile
    empty
    ones
  )], 'list-files';

is_deeply [scs_archive(qw[ --list-dirs --mount ], $file)],
  [qw(
    dir
    dir/subdir
    emptydir
  )], 'list-dirs';

is_deeply [scs_archive(qw[ --list-orphans --mount ], $file)],
  ['4063fbd34a25e9f0'], 'list-orphans';

is_deeply [scs_archive(qw[ --extract --output - ones --mount ], $file)],
  ['1' x 100], 'extract';

is_deeply [scs_archive(qw[ -x -o - ones -m ], $file)],
  ['1' x 100], 'extract abbr';

# Extract from single archive file

is scs_archive(qw[ -x 4063fbd34a25e9f0 ], -o => $tempdir, -m => $file), '', 'extract orphan ok';
ok path("$tempdir/4063fbd34a25e9f0")->exists, 'orphan';

is scs_archive(qw[ -x dir ], -o => $tempdir, -m => $file), '', 'extract dir ok';
ok path("$tempdir/dir")->exists, 'dir';
is_deeply [path("$tempdir/dir")->children], [], 'dir empty';

is scs_archive(qw[ -x dir --recursive ], -o => $tempdir, -m => $file), '', 'extract dir recursive ok';
ok path("$tempdir/dir/subdir/SubDirFile")->exists, 'dir recursive';

is scs_archive(qw[ -x dir -r ], -o => "$tempdir/abbr", -m => $file), '', 'extract dir recursive abbr';
ok path("$tempdir/abbr/dir/subdir/SubDirFile")->exists, 'recursive abbr';


done_testing;
