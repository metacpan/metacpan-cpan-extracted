# SPDX-FileCopyrightText: SUSE LLC
# SPDX-License-Identifier: GPL-2.0-or-later
#
# Developer-only differential test (author test - not run by a normal `make test`; run explicitly with
# `prove -b xt/`). While Cavil still ships alongside the previous engine, this proves Cavil::Matcher is
# byte-for-byte equivalent to Spooky::Patterns::XS across every public operation, on the real pattern
# corpus and real production snippets. Once Spooky::Patterns::XS is retired this file can simply be
# deleted; the self-contained t/ suite fully covers Cavil::Matcher on its own.
use strict;
use warnings;
use Test::More;
use Test::Deep;
use Cavil::Matcher;

BEGIN {
  plan skip_all => 'Spooky::Patterns::XS not installed (developer-only differential test)'
    unless eval { require Spooky::Patterns::XS; 1 };
}

sub slurp  { open my $fh, '<:raw', $_[0] or die $!; local $/; my $c = <$fh>; close $fh; $c }
sub scores { [map { sprintf '%.4f', $_->{match} } @{$_[0]}] }

Cavil::Matcher::init_matcher();
Spooky::Patterns::XS::init_matcher();

# --- parse_tokens / normalize / distance / read_lines on the fixtures ----------------------------
my %pat;
for my $fn (glob('t/fixtures/licenses/04license.*.pattern')) {
  $fn =~ m/\.(\d+)\.pattern$/ or next;
  $pat{$1} = slurp($fn);
}
for my $id (sort { $a <=> $b } keys %pat) {
  cmp_deeply(
    Cavil::Matcher::parse_tokens($pat{$id}),
    Spooky::Patterns::XS::parse_tokens($pat{$id}),
    "parse_tokens identical for pattern $id"
  );
}

my @texts = (
  glob('t/fixtures/text/*.in'), 't/fixtures/text/07close.p1',
  't/fixtures/text/07close.p2', glob('t/fixtures/licenses/04license.*.txt')
);
for my $fn (@texts) {
  next unless -r $fn;
  my $text = slurp($fn);
  cmp_deeply(Cavil::Matcher::normalize($text), Spooky::Patterns::XS::normalize($text), "normalize identical for $fn");
}

my $p1c = Cavil::Matcher::normalize(slurp('t/fixtures/text/07close.p1'));
my $p2c = Cavil::Matcher::normalize(slurp('t/fixtures/text/07close.p2'));
my $p1s = Spooky::Patterns::XS::normalize(slurp('t/fixtures/text/07close.p1'));
my $p2s = Spooky::Patterns::XS::normalize(slurp('t/fixtures/text/07close.p2'));
is(Cavil::Matcher::distance($p1c, $p2c), Spooky::Patterns::XS::distance($p1s, $p2s), 'distance identical');

for my $fn ('t/fixtures/text/03match.txt', 't/fixtures/licenses/04license.12.txt') {
  my %needed = map { $_ => 1 } (1, 4, 115, 9999);
  cmp_deeply(
    Cavil::Matcher::read_lines($fn, {%needed}),
    Spooky::Patterns::XS::read_lines($fn, {%needed}),
    "read_lines identical for $fn"
  );
}

# --- find_matches over the license corpus --------------------------------------------------------
my $cm = Cavil::Matcher::init_matcher();
my $sm = Spooky::Patterns::XS::init_matcher();
for my $id (sort { $a <=> $b } keys %pat) {
  $cm->add_pattern($id, Cavil::Matcher::parse_tokens($pat{$id}));
  $sm->add_pattern($id, Spooky::Patterns::XS::parse_tokens($pat{$id}));
}
for my $fn (sort glob('t/fixtures/licenses/04license.*.txt')) {
  cmp_deeply($cm->find_matches($fn), $sm->find_matches($fn), "find_matches identical for $fn");
}

# --- bag score parity on real snippets -----------------------------------------------------------
my $cbag   = Cavil::Matcher::init_bag_of_patterns;
my $sbag   = Spooky::Patterns::XS::init_bag_of_patterns;
my $shared = {%pat};
$cbag->set_patterns($shared);
$sbag->set_patterns($shared);
for my $fn (glob('t/fixtures/snippets/*.txt'), glob('t/fixtures/licenses/04license.*.txt')) {
  next if $fn =~ /INDEX/;
  my $text = slurp($fn);
  cmp_deeply(scores($cbag->best_for($text, 3)), scores($sbag->best_for($text, 3)), "bag scores identical for $fn");
}

# --- large-scale corpus differential (real production patterns), if available --------------------
my $jsonl = $ENV{CAVIL_MATCHER_CORPUS_FILE} // '../cavil/lib/Cavil/resources/license_patterns.jsonl';
SKIP: {
  skip 'production corpus not available', 1 unless -r $jsonl && eval { require Cpanel::JSON::XS; 1 };
  my $limit = $ENV{CAVIL_MATCHER_CORPUS} || 4000;
  open my $fh, '<', $jsonl or die $!;
  my $bigc = Cavil::Matcher::init_matcher();
  my $bigs = Spooky::Patterns::XS::init_matcher();
  my (@sample, $id);
  while (my $line = <$fh>) {
    last if ++$id > $limit;
    my $row = Cpanel::JSON::XS::decode_json($line);
    next unless defined $row->{pattern} && length $row->{pattern};
    $bigc->add_pattern($id, Cavil::Matcher::parse_tokens($row->{pattern}));
    $bigs->add_pattern($id, Spooky::Patterns::XS::parse_tokens($row->{pattern}));
    push @sample, $row->{pattern} if $id % 40 == 0 && @sample < 120;
  }
  close $fh;

  require File::Temp;
  my $mismatch = 0;
  for my $text (@sample) {
    my ($tfh, $tname) = File::Temp::tempfile(UNLINK => 1);
    binmode $tfh;
    my $bytes = "$text\n";
    utf8::encode($bytes);
    print {$tfh} $bytes;
    close $tfh;
    $mismatch++ unless eq_deeply($bigc->find_matches($tname), $bigs->find_matches($tname));
  }
  is($mismatch, 0, "find_matches identical across corpus on @{[scalar @sample]} sampled texts");
}

done_testing();
