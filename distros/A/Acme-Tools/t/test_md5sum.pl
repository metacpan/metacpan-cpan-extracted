#!/usr/bin/perl
use Acme::Tools;
print eval{ md5sum($_)."  $_\n" } || $@ for @ARGV;
