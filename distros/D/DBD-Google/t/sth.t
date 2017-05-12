#!/usr/bin/perl
# vim: set ft=perl:

use DBI;
use Test::More;

plan tests => 2;

my %opts = ("oe" => "utf-8",
            "ie" => "utf-8",
            "safe" => 0,
            "filter" => 1);

my $dbh = DBI->connect("dbi:Google:", 'x' x 32, undef, \%opts);
my $sth = $dbh->prepare("SELECT * FROM google WHERE q = 'perl DBI'");

ok($dbh, "Database handle");
ok($sth, "Statement handle");

