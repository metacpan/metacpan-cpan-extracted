
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use strict;
use warnings;
use File::Find ();
use Test::More;

# Every module under lib/ carries the version of the main module. Core is
# versioned from its main module only (VersionFromMainModule) and nothing
# rewrites the other modules on a version bump, so this is what notices one
# left behind. Paths are relative to the distribution root.
my $main = 'lib/DBIO.pm';

# The literal $VERSION assignment of a file, or undef when it has none.
sub version_of {
  my ($file) = @_;
  open my $fh, '<:encoding(UTF-8)', $file or die "cannot read $file: $!";
  while (my $line = <$fh>) {
    return $1 if $line =~ /^\s*(?:our\s+)?\$VERSION\s*=\s*['"]?([0-9][0-9._]*)['"]?\s*;/;
  }
  return undef;
}

my $want = -f $main ? version_of($main) : undef;
ok defined $want, "main module $main carries a literal \$VERSION"
  or BAIL_OUT 'no main module version to compare against -- run this test from the distribution root';

my @files;
File::Find::find({
  no_chdir => 1,
  wanted   => sub { push @files, $_ if -f && /\.pm\z/ },
}, 'lib');
ok scalar(@files), 'found modules under lib/';

for my $file (sort @files) {
  my $have = version_of($file);
  ok defined $have && $have eq $want,
    "$file carries version $want"
    or diag defined $have
      ? "$file has \$VERSION $have, the main module has $want"
      : "$file has no literal \$VERSION, the main module has $want";
}

done_testing;
