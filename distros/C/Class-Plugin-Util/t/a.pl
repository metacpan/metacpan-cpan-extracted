#!/usr/local/bin/perl
use strict;
use Class::Plugin::Util qw(factory_new);
use warnings 'Class::Plugin::Util';

my $m  = 'Getopt::LLx';
my $ll = factory_new($m);

#my $args = $ll->result;
#use YAML;
#print YAML::Dump($args);

print "^^^^^^^^^^^^^^ [HELLO WORLD!] ^^^^^^^^^^^^^^\n";
my $lx = factory_new($m);
print "^^^^^^^^^^^^^^ [HELLO SPACE!] ^^^^^^^^^^^^^^\n";
