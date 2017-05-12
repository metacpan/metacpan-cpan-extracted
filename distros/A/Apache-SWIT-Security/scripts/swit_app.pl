#!/usr/bin/perl -w
use strict;
use lib 'lib';
use Apache::SWIT::Security::Maker;
my $f = shift(@ARGV);
Apache::SWIT::Security::Maker->new->$f(@ARGV);
