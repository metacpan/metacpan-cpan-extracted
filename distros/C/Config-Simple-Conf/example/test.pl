#!/usr/bin/perl
use lib 'lib';
use strict;
use Config::Simple::Conf;
use Data::Dumper;
my $conf = shift @ARGV;
push @ARGV, '--global_c_argv=[global_c]', '--argv-example=abc', '--argv-example2', 'xyz';

print Dumper(Config::Simple::Conf->new($conf || "example/test_inc.conf"));
