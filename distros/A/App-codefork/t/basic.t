#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Path::Tiny;
use App::codefork;

my $tmpdir = Path::Tiny->tempdir;

# Create test files
$tmpdir->child('HomeHive.pm')->spew("package HomeHive;\nmy \$hh = 1;\n");
$tmpdir->child('lib')->mkpath;
$tmpdir->child('lib/HomeHive.pm')->spew("package HomeHive::Core;\n");

# Create config outside of work dir
my $confdir = Path::Tiny->tempdir;
my $config = $confdir->child('fork.conf');
$config->spew("HomeHive|AqHive\nhomehive|aqhive\nhh%ah\n");

my $app = App::codefork->new(
  config => $config->stringify,
  dir => $tmpdir->stringify,
);

# Test collect_changes
my $changes = $app->collect_changes;
ok(scalar @$changes > 0, 'changes detected');

my %by_old = map { $_->{old_path} => $_ } @$changes;

# File rename
ok(exists $by_old{'HomeHive.pm'}, 'HomeHive.pm found in changes');
is($by_old{'HomeHive.pm'}{new_path}, 'AqHive.pm', 'filename renamed');

# Content replacement
like($by_old{'HomeHive.pm'}{new_content}, qr/package AqHive;/, 'replace in content');
like($by_old{'HomeHive.pm'}{new_content}, qr/\$ah = 1/, 'word replacement in content');

# Subdirectory file
ok(exists $by_old{'lib/HomeHive.pm'}, 'lib/HomeHive.pm found');
is($by_old{'lib/HomeHive.pm'}{new_path}, 'lib/AqHive.pm', 'subdir file renamed');

# Test generate_diff
my $diff = $app->generate_diff($changes);
like($diff, qr/^---/m, 'diff contains --- header');
like($diff, qr/^\+\+\+/m, 'diff contains +++ header');
like($diff, qr/AqHive/, 'diff contains replacement');

# Files should be unchanged (dry-run)
is($tmpdir->child('HomeHive.pm')->slurp, "package HomeHive;\nmy \$hh = 1;\n",
  'original file unchanged after collect/diff');

# Test apply_changes
my $count = $app->apply_changes($changes);
is($count, scalar @$changes, 'apply returns change count');
ok(!$tmpdir->child('HomeHive.pm')->exists, 'old file removed after apply');
ok($tmpdir->child('AqHive.pm')->exists, 'new file exists after apply');
like($tmpdir->child('AqHive.pm')->slurp, qr/package AqHive;/, 'content replaced after apply');
like($tmpdir->child('AqHive.pm')->slurp, qr/\$ah = 1/, 'word replaced after apply');

done_testing;
