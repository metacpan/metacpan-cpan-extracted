#!/usr/bin/perl

use warnings;
use strict;

use ApacheLog::Parser::Report;
use YAML;

my $conf_file = shift(@ARGV) or die "need config file";

my ($config) = YAML::LoadFile($conf_file);
my $rep = ApacheLog::Parser::Report->new(conf => $config);

# TODO something less ugly
$ENV{DBG} = 1;
my $func = $rep->get_func;

# vim:ts=2:sw=2:et:sta
