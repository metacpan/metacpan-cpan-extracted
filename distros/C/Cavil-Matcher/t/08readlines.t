# SPDX-FileCopyrightText: SUSE LLC
# SPDX-License-Identifier: GPL-2.0-or-later
#
# read_lines() returns selected lines as raw (undecoded) bytes; it backs snippet extraction and the
# content checksums. Self-contained pinned expectations.
use strict;
use warnings;
use Test::More;
use Test::Deep;
use Cavil::Matcher;
use utf8;

# Basic line selection.
cmp_deeply(
  Cavil::Matcher::read_lines('t/fixtures/text/03match.txt', {4 => 1}),
  [[4, 1, 'Hello world, this is a test']],
  'returns the requested line'
);

# The value column comes from the request hash.
cmp_deeply(
  Cavil::Matcher::read_lines('t/fixtures/text/03match.txt', {4 => 42}),
  [[4, 42, 'Hello world, this is a test']],
  'value column echoes the request hash value'
);

# Returned strings are raw bytes (not flagged UTF-8), matching how source files are stored.
my $ret = Cavil::Matcher::read_lines('t/fixtures/text/05readlines.1.txt', {1 => 1});
my $str = $ret->[0][2];
is(utf8::is_utf8($str) ? 1 : 0, 0, 'not returned as a decoded UTF-8 string');
utf8::decode($str);
is($str, 'la araña is a böses Tier', 'unicode content preserved as bytes');

# End-of-file line without a trailing newline is still returned.
cmp_deeply(
  Cavil::Matcher::read_lines('t/fixtures/licenses/04license.12.txt', {115 => 1}),
  [[115, 1, 'END OF TERMS AND CONDITIONS']],
  'last line (no trailing newline) returned'
);

# Multiple lines, some missing; a binary file; a missing file - none crash.
my $multi = Cavil::Matcher::read_lines('t/fixtures/text/03match.txt', {1 => 1, 4 => 1, 9999 => 1});
is(scalar @$multi, 2, 'only existing requested lines are returned');
ok(ref(Cavil::Matcher::read_lines('t/fixtures/text/05readlines.2.raw', {1 => 1})) eq 'ARRAY',
  'binary file does not crash');
cmp_deeply(Cavil::Matcher::read_lines('t/does-not-exist', {1 => 1}), [], 'missing file returns empty');

done_testing();
