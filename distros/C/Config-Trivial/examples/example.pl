#!/usr/bin/perl

# $Id: example.pl 51 2014-05-21 19:14:11Z adam $

use strict;
use Config::Trivial;

my $config = Config::Trivial->new(
    config_file => "./example.conf"
);

my $settings = $config->read();

print "My book is '$settings->{'book'}'.\n";

print "Roses are '$settings->{'colour'}'.\n";

print "'$settings->{'animal'}' Pâté tastes nice.\n";
