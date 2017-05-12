#!/usr/bin/env perl

use feature 'say';
use strictures 2;

use Bot::Cobalt::DB;
use DateTime;

my $rdb = shift @ARGV;
my $out = shift @ARGV;
my $year = shift @ARGV || DateTime->from_epoch(epoch => time)->year;
die "Expected a RDB path and an output path"
  unless defined $rdb and defined $out;
die "No such RDB: '$rdb'"
  unless -e $rdb;

my $dbh = Bot::Cobalt::DB->new(file => $rdb);
my @items;
$dbh->dbopen or die "dbopen failure";
for my $key ($dbh->dbkeys) {
  my $item = $dbh->get($key);
  my $dt = DateTime->from_epoch(epoch => $item->[1]);
  push @items, $item if $dt->year == $year;
}
$dbh->dbclose;
die "No items found" unless @items;

die "output file '$out' already exists" if -e $out;
open my $outfh, '>', $out or die "open: $!";
for my $item (@items) {
  print $outfh $item->[0], "\n\n"
}
close $outfh;
say "Done";
