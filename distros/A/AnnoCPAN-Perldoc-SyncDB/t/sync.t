#!/usr/bin/perl

use warnings;
use strict;
use File::Temp qw(tempfile);

BEGIN
{
   use Test::More tests => 6;
   use_ok("AnnoCPAN::Perldoc::SyncDB");
}

# The main plan: Create two tempfiles and use this module to mirror
# one onto the other.  If it succeeds the resulting files should be
# identical.  To do this, force a file:// url for LWP.
#   --> Will the file:// url work on other platforms?


# Ensure that tempfile2 is older than tempfile1
my ($fh2, $tempfile2) = tempfile(UNLINK => 1);
print $fh2 "";
close $fh2;
sleep(2);
my ($fh1, $tempfile1) = tempfile(UNLINK => 1);
print $fh1 "Foo\n";
close $fh1;

# shorthand:
my $pkg = "AnnoCPAN::Perldoc::SyncDB";

my $url = $pkg->baseurl();
ok($url, "baseurl");
is($pkg->baseurl("foo"), "foo", "baseurl");
is($pkg->baseurl($url), $url, "baseurl");
$pkg->run(
   src => "file://$tempfile1",
   dest => $tempfile2,
   compress => '',
   #verbose => 1,
);
ok(-f $tempfile2, "run");
is(-s $tempfile2, -s $tempfile1, "run");
