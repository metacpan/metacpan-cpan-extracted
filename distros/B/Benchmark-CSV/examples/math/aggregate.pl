#!/usr/bin/env perl
# FILENAME: aggregate.pl
# CREATED: 09/16/14 23:34:03 by Kent Fredric (kentnl) <kentfredric@gmail.com>
# ABSTRACT: Aggregate csv entries.

use strict;
use warnings;
use utf8;

my $bucket_size = 0.00001;

use Path::Tiny;
use FindBin;
use POSIX qw( floor );
my $source = path($FindBin::Bin)->child('out.csv')->openr;
my $header = scalar <$source>;
chomp $header;
my (@headings) = split q/,/, $header;
my $buckets = [];

while ( my $line = <$source> ) {
  chomp $line;
  my (@fields) = split q/,/, $line;
  for ( 0 .. $#fields ) {
    my $wrapped = $bucket_size * floor( $fields[$_] / $bucket_size );
    $buckets->[$_] ||= {};
    $buckets->[$_]->{$wrapped} ||= 0;
    $buckets->[$_]->{$wrapped}++;
  }
}

my $sbuckets = [];
for my $sbucket ( @{$buckets} ) {
  my $obucket = [];
  for my $key ( sort { $a <=> $b } keys %{$sbucket} ) {
    push @{$obucket}, [ $key, sprintf "%f", $sbucket->{$key} ];
  }
  push @{$sbuckets}, $obucket;
}

my $target = path($FindBin::Bin)->child('out_hist.csv')->openw;

printf {$target} "%s\n", join q[,], map { ( q[], $_ ) } @headings;

sub has_sbucket {
  for my $bucket ( @{$sbuckets} ) {
    return 1 if @{$bucket};
  }
}

while ( has_sbucket() ) {
  my @row;
  for my $bucket ( @{$sbuckets} ) {
    my $item = shift @{$bucket};
    push @row, @{ $item || [ '', '' ] };
  }
  printf {$target} "%s\n", join q[,], @row;
}

