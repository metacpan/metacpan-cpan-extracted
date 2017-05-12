#!/usr/bin/perl

use warnings;
use strict;

use ApacheLog::Parser::SkipList;
use YAML;

my ($config, $skipfile) = @ARGV or die "usage: <config> <file>";

my ($conf) = YAML::LoadFile($config);

my $skipper = ApacheLog::Parser::SkipList->new;
$skipper->set_config($conf);
my $sr = $skipper->new_reader($skipfile);
while(my $num = $sr->next_skip) {
  print "skip $num", ($sr->[1] ? " +$sr->[1]" : ''), "\n";
}

# vim:ts=2:sw=2:et:sta
