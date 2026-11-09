
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use strict;
use warnings;
use File::Find ();
use Pod::Checker ();
use Test::More;

# Pod::Checker over the built distribution: modules under lib/, scripts under
# bin/. This is the woven POD -- what gets installed -- so it catches what no
# source file shows, above all an L</name> whose heading the woven document
# does not have ("unresolved internal link").
#
# Paths are relative to the distribution root, which is where `make test` and
# `prove` run from.
my @files;
for my $dir (grep { -d } qw(lib bin)) {
  File::Find::find({
    no_chdir => 1,
    wanted   => sub {
      push @files, $_ if -f && ($dir eq 'bin' || /\.(?:pm|pod)\z/);
    },
  }, $dir);
}

# Started from the wrong directory this would otherwise pass on nothing.
ok scalar(@files), 'found files to check under lib/ and bin/'
  or diag 'nothing found -- run this test from the distribution root';

for my $file (sort @files) {
  my $report = '';
  open my $out, '>:encoding(UTF-8)', \$report
    or die "cannot open in-memory handle: $!";

  # Errors only: warnings are not reported, so a green run stays quiet.
  my $checker = Pod::Checker->new(-warnings => 0);
  $checker->parse_from_file($file, $out);
  close $out;

  # num_errors is -1 for a file without any POD -- nothing to check, no fault.
  ok $checker->num_errors <= 0, "POD of $file"
    or diag $report;
}

done_testing;
