# SPDX-FileCopyrightText: SUSE LLC
# SPDX-License-Identifier: GPL-2.0-or-later
#
# Scalability property: a compiled segment is memory-mapped read-only and queried in place, so
# attaching it to many matchers adds almost no *private* (anonymous) memory - the segment lives in the
# shared page cache, one physical copy per host across all index workers. The previous engine rebuilt
# a full heap copy per matcher; this test proves the new engine does not. We measure RssAnon (Linux),
# which excludes file-backed mmap pages, so a heap-copy design would show ~N x segment size here while
# the mmap design shows ~0.
use strict;
use warnings;
use Test::More;
use Cavil::Matcher;
use File::Temp qw(tempdir);

sub rss_anon_bytes {
  open my $fh, '<', '/proc/self/status' or return undef;
  while (my $l = <$fh>) { return $1 * 1024 if $l =~ /^RssAnon:\s+(\d+)\s+kB/ }
  return undef;
}

plan skip_all => 'RssAnon not available (non-Linux?)' unless defined rss_anon_bytes();

sub slurp { open my $fh, '<:raw', $_[0] or die $!; local $/; my $c = <$fh>; close $fh; $c }

# Build a reasonably large segment. Prefer the real corpus; fall back to replicating the fixtures.
my $dir     = tempdir(CLEANUP => 1);
my $builder = Cavil::Matcher::init_matcher();
my $id      = 0;
my $jsonl   = $ENV{CAVIL_MATCHER_CORPUS_FILE} // '../cavil/lib/Cavil/resources/license_patterns.jsonl';
if (-r $jsonl && eval { require Cpanel::JSON::XS; 1 }) {
  open my $fh, '<', $jsonl or die $!;
  while (my $line = <$fh>) {
    last if $id >= 8000;
    my $row = Cpanel::JSON::XS::decode_json($line);
    next unless defined $row->{pattern} && length $row->{pattern};
    $builder->add_pattern(++$id, Cavil::Matcher::parse_tokens($row->{pattern}));
  }
  close $fh;
}
else {
  my %pat;
  for my $fn  (glob('t/fixtures/licenses/04license.*.pattern')) { $fn =~ /\.(\d+)\.pattern$/ and $pat{$1} = slurp($fn) }
  for my $rep (1 .. 200) {
    $builder->add_pattern(++$id, Cavil::Matcher::parse_tokens("rep$rep $pat{$_}")) for keys %pat;
  }
}

my $seg = "$dir/big.seg";
ok($builder->dump($seg), 'compiled a large segment');
my $F = -s $seg;
ok($F > 100_000, "segment is sizable ($F bytes)");

my $scan_file = (glob('t/fixtures/licenses/04license.*.txt'))[0];

my $before = rss_anon_bytes();
my $N      = 25;
my @keep;
for (1 .. $N) {
  my $m = Cavil::Matcher::init_matcher();
  ok($m->attach($seg), 'attached shared segment') if $_ == 1;
  $m->attach($seg) unless $_ == 1;
  $m->find_matches($scan_file);    # fault pages in
  push @keep, $m;                  # keep all matchers alive simultaneously
}
my $delta = rss_anon_bytes() - $before;

# A per-matcher heap copy would cost about N x F of anonymous memory. The mmap-shared design costs
# essentially none. Assert the private-memory growth is far below even a single copy of the segment.
diag(sprintf(
  'attached %d matchers over a %d-byte segment; RssAnon grew %d bytes (heap-copy would be ~%d)',
  $N, $F, $delta, $N * $F
));
cmp_ok($delta, '<', $F, 'attaching N matchers adds less private memory than a single segment copy');

# Sanity: the kept matchers still match correctly.
ok(ref $keep[0]->find_matches($scan_file) eq 'ARRAY', 'shared matchers still work');

done_testing();
