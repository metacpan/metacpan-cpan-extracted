#!/usr/bin/perl -w
use strict;
use Archive::SelfExtract;
use File::Spec::Functions;

# This is run by the test suite.
# If things don't look kosher, die.

foreach my $x qw( a b c ) {
  my $fn = catfile( $Archive::SelfExtract::Tempdir, "test", $x, "$x.txt" );
  die "No $fn" unless -e $fn;
  open(my $f, $fn) || die "Can't open $fn ($!)";
  my $line = <$f>;
  chomp($line);
  die "Archived data appears corrupt" unless lc($line) eq $x;
  #print "Yay! $x\n";
  close($f);
}

#print "Deleting $Archive::SelfExtract::Tempdir\n";
Archive::SelfExtract::cleanup();
