use strict;
use warnings;
use Test::More;

use File::Find ();
use version ();

# THE CLAIM THIS TEST MAKES (house rule 11 -- stated up front, so that a
# future fix has to say whether it keeps this claim or replaces it):
#
#   "The next release of this distribution takes over the PAUSE index entry
#    for EVERY tombstone name shipped here."
#
# The takeover is decided by THIS dist's release version alone -- the build
# stamps it into every module and into META "provides" (MetaProvides::Package,
# inherit_version = 1), so the $VERSION literal in a stub records the fact but
# does not cause it. Existing tombstones cannot be overtaken: their origin
# releases are frozen and no origin dist ships those names any more.
#
# That leaves exactly ONE failure mode, and it fails SILENTLY: a NEWLY added
# tombstone inherits whatever version this dist is released at. If
# DBIO-Deprecated lags behind the family, that version can be LOWER than the
# origin release that last shipped the orphaned name -- clean build, green
# tests, and PAUSE still pointing at the stale pre-rename/pre-removal code.
# This guard is what makes that loud, before the release instead of after it.
#
# Operationalised as two assertions:
#
#   1. Every lib/**/*.pm except the main module carries EXACTLY ONE parseable
#      line "# Last release that shipped this name: <Dist> <X.Y>."
#      A missing or unparseable line is a FAILURE, not a skip -- that branch
#      is part of the claim. Without it the guard could be defeated by a new
#      tombstone simply omitting the line, which is precisely the mistake the
#      guard exists to catch.
#
#   2. $DBIO::Deprecated::VERSION is STRICTLY GREATER than the maximum of all
#      origin releases read that way. Checked per file too, so a failure names
#      the offending tombstone instead of only the aggregate.
#
# The origin releases are read out of the tombstones themselves rather than
# kept as a hand-maintained constant in this file: a new tombstone must extend
# the guard automatically. A hand-maintained number is exactly the kind of
# statement that has already gone quietly stale in this repository once.

# "# Last release that shipped this name: DBIO-MySQL-Async 0.900000."
# "# Last release that shipped this name: DBIO (core) 0.900002."
# The distribution part may contain spaces; the version is the last token
# before the closing period.
my $ORIGIN_RE = qr{
  ^ \s* \# \s*
  Last \s release \s that \s shipped \s this \s name: \s*
  (\S.*?)                                        # origin distribution
  \s+
  ( v? [0-9]+ (?: \. [0-9]+ )* (?: _ [0-9]+ )? ) # origin release version
  \s* \. \s* $
}x;

my $LIB_DIR     = 'lib';
my $MAIN_MODULE = 'lib/DBIO/Deprecated.pm';

# A guard that quietly checks nothing is worse than no guard, so neither
# "lib/ is not where I expect it" nor "found no tombstones at all" may end in
# a pass. BAIL_OUT rather than plan skip_all deliberately: skip_all is GREEN,
# and a green run would report that the takeover is safe when in truth nothing
# was examined. Both conditions mean the guard could not run, which must never
# look like the guard succeeding.
BAIL_OUT("no '$LIB_DIR' directory below cwd -- run this from the dist root")
  unless -d $LIB_DIR;

my @tombstones;
File::Find::find(
  {
    no_chdir => 1,
    wanted   => sub {
      return unless /\.pm\z/;
      return if $File::Find::name eq $MAIN_MODULE;
      push @tombstones, $File::Find::name;
    },
  },
  $LIB_DIR,
);
@tombstones = sort @tombstones;

BAIL_OUT("found no tombstone modules under '$LIB_DIR' -- guard is inoperative")
  unless @tombstones;

require DBIO::Deprecated;
my $dist_version = $DBIO::Deprecated::VERSION;
BAIL_OUT('DBIO::Deprecated carries no $VERSION -- cannot check the takeover')
  unless defined $dist_version && length $dist_version;
my $dist_v = version->parse($dist_version);

my %origin_for;

for my $file (@tombstones) {
  open my $fh, '<', $file or BAIL_OUT("cannot read $file: $!");
  my @found;
  while (my $line = <$fh>) {
    push @found, { dist => $1, version => $2 } if $line =~ $ORIGIN_RE;
  }
  close $fh;

  # Exactly one -- zero means the origin release was never recorded (the
  # omission that would defeat the guard), more than one means it is recorded
  # twice and the guard could not say which one governs.
  unless (is(scalar @found, 1,
      "$file records exactly one parseable origin release")) {
    diag("$file: expected a line of the form\n"
      . "  # Last release that shipped this name: <Distribution> <X.Y>.\n"
      . 'found ' . scalar(@found) . ' such line(s)');
    next;
  }

  $origin_for{$file} = $found[0];
}

for my $file (@tombstones) {
  my $origin = $origin_for{$file} or next;   # already failed above
  my $origin_v = version->parse($origin->{version});

  ok($dist_v > $origin_v,
    "$file: dist version $dist_version beats origin release "
      . "$origin->{dist} $origin->{version}")
    or diag("PAUSE takeover would FAIL for this tombstone.\n"
      . "  file:            $file\n"
      . "  origin release:  $origin->{dist} $origin->{version}\n"
      . "  this dist:       DBIO-Deprecated $dist_version\n"
      . 'Raise $VERSION in ' . "$MAIN_MODULE above $origin->{version} "
      . '(raising the literal in the stub does NOT help -- the build '
      . 'overwrites it).');
}

# The aggregate the claim is actually about: one number to beat, named.
if (keys %origin_for) {
  my ($highest_file) = sort {
    version->parse($origin_for{$b}{version})
      <=> version->parse($origin_for{$a}{version})
      || $a cmp $b
  } keys %origin_for;
  my $highest = $origin_for{$highest_file};

  ok($dist_v > version->parse($highest->{version}),
    "DBIO-Deprecated $dist_version beats the highest origin release "
      . "$highest->{dist} $highest->{version} (from $highest_file)");
}

done_testing();
