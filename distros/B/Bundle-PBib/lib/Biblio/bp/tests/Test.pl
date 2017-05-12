#!/usr/bin/perl

unshift(@INC, $ENV{'BPHOME'})  if defined $ENV{'BPHOME'};
require "bp.pl";
&bib'load_format('bibtex');
&bib'load_format('refer');

$intest = 1;

print "begin testing\n\n";

do 'sub/nametest.pl';
do 'sub/datetest.pl';

print "\nend testing\n";
