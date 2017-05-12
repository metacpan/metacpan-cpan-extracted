#!/usr/bin/perl

unshift(@INC, $ENV{'BPHOME'})  if defined $ENV{'BPHOME'};

$start = (times)[0];
printf "Startup: %.2f seconds\n\n", $start;

$bibpackage_do_not_load_defaults = 1;
require "bp.pl";
$end = (times)[0];
printf "Loading package: %.2f seconds\n\n", $end - $start;
$start = $end;

&bib'format("auto");
&bib'errors("clear");
$end = (times)[0];
printf "Loading defaults: %.2f seconds\n\n", $end - $start;
$start = $end;

&bib'load_charset("troff");
$end = (times)[0];
printf "Loading troff: %.2f seconds\n\n", $end - $start;
$start = $end;

&bib'load_format("refer");
$end = (times)[0];
printf "Loading refer: %.2f seconds\n\n", $end - $start;
$start = $end;

&bib'load_charset("tex");
$end = (times)[0];
printf "Loading tex: %.2f seconds\n\n", $end - $start;
$start = $end;

&bib'load_format("bibtex");
$end = (times)[0];
printf "Loading bibtex: %.2f seconds\n\n", $end - $start;
$start = $end;

printf "Total time: %.2f seconds\n\n", (times)[0];



@ARGV = &bib'stdargs(@ARGV);
$end = (times)[0];
printf "stdarg processing: %.2f seconds\n", $end - $start;
$start = $end;


print "Testing timing on a 425 record refer file.\n\n";
$file = "../ref/ad425.ref";
#$file = "../../alldec.ref";

open(REF, $file);
while (<REF>) { }
close(REF);
$end = (times)[0];
printf "raw: read with no processing: %.2f seconds\n", $end - $start;
$start = $end;

if (1) {
&bib'format("refer");
&bib'open($file);
while (&bp_refer'read($file) ) { }
&bib'close($file);
$end = (times)[0];
printf "bpr: read with no processing: %.2f seconds\n", $end - $start;
$start = $end;
}

&bib'format("refer");
&bib'open($file);
while (&bib'read($file)) { }
&bib'close($file);
$end = (times)[0];
printf " bp: read with no processing: %.2f seconds\n", $end - $start;
$start = $end;

print "\n";


$totr = 1;
open(REF, $file);
while (<REF>) {
  next if /^\%/;
  next if /\w/;
  $totr++;
  while (<REF>) { last if /^\%/; }
}
close(REF);
$end = (times)[0];
printf "raw: count $totr records:  %.2f seconds\n", $end - $start;
$start = $end;

$totr = 0;
&bib'format("refer");
&bib'open($file);
while (&bib'read($file)) { $totr++; }
&bib'close($file);
$end = (times)[0];
printf " bp: count $totr records:  %.2f seconds\n", $end - $start;
$start = $end;

print "\n";

$totf = 0;
%field = ();
open(REF, $file);
while (<REF>) {
  last if /^\%/;
}
$fn = '';
while (/^\%(.) (.*)/) {
  if ($1 ne $fn) {
    $fn = $1;
    $field{$fn}++;
  }
  while (<REF>) {
    last if /^\%/;
    $fn = '' if /^\s*$/;
  }
  last if eof;
}
foreach $f (keys %field) { $totf += $field{$f}; }
#foreach $f (keys %field) { print "$f: $field{$f}\n"; }
close(REF);
$end = (times)[0];
printf "raw: count $totf fields:  %.2f seconds\n", $end - $start;
$start = $end;

$totf = 0;
%field = ();
&bib'format("refer");
&bib'open($file);
while ($rec = &bib'read($file)) {
  %ent = &bib'explode($rec);
  grep($field{$_}++, keys %ent);
}
foreach $f (keys %field) { $totf += $field{$f}; }
#foreach $f (keys %field) { print "$f: $field{$f}\n"; }
&bib'close($file);
$end = (times)[0];
printf " bp: count $totf fields:  %.2f seconds\n", $end - $start;
$start = $end;

