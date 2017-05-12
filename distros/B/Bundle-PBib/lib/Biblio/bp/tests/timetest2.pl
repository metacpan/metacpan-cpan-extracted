#!/usr/bin/perl

# $size = 425;
$size = 2608;

# If we have perl 5, we can save the exploded data in a list.  This will
# use more memory (on my system, running the 2608 record test took 4.9 MB
# up from 3.2 MB for just storing the input string).  But the program will
# run quite a bit faster since we don't have to keep exploding the record
# for each test.
# Note that the reported times should be similar, since we subtract the
# time taken for exploding when we report.
if ($] >= 5) {
  $save_hash = 1;
} else {
  $save_hash = 0;
}
#$save_hash = 0;

unshift(@INC, $ENV{'BPHOME'})  if defined $ENV{'BPHOME'};

$start = (times)[0];
require "bp.pl";
&bib'load_format("refer");
&bib'load_format("bibtex");
#&bib'load_format("powells");
&bib'errors('ignore', 'exit');
@ARGV = &bib'stdargs(@ARGV);

$end = (times)[0];
printf "Loading package: %.2f seconds\n\n", $end - $start;
$start = $end;

if ($size == 425) {
  $rfile = "../ref/ad425.ref";
  $bfile = "../ref/ad425.bib";
} elsif ($size == 2608) {
  $rfile = "../../alldec.ref";
  $bfile = "../../alldec.bib";
} else {
  warn "Unknown size file requested!  Using 425.\n";
  $size = 425;
  $rfile = "../ref/ad425.ref";
  $bfile = "../ref/ad425.bib";
}

$ref_test = 1;
$btx_test = 1;

if ($ref_test) {

print "Testing timing on a $size record file.\n\n";


print "  bp: refer          read: ";

&bib'format("refer");
&bib'open($rfile);
$i = 0;  @rec = (); @savehash = ();
while ($record = &bib'read) {
  $rec[$i++] = $record;
}
&bib'close;
$end = (times)[0];
printf " %5.2f seconds  ($i records)\n", $end - $start;
$start = $end;

print "  bp: refer       explode: ";

if ($save_hash) {
  while (@rec) {
     push @savehash, { &bib'explode(shift @rec) };
  }
} else {
  foreach (@rec) {
     %ent = &bib'explode($_);
  }
}
$end = (times)[0];
$etime = $end - $start;
printf " %5.2f seconds\n", $etime;
$start = $end;

$etime = 0 if $save_hash;

print "  bp: refer       implode: ";

if ($save_hash) {
  foreach $hash ( @savehash ) {
    $irec = &bib'implode(%$hash);
  }
} else {
  foreach (@rec) {
     $irec = &bib'implode(&bib'explode($_));
  }
}
$end = (times)[0];
printf " %5.2f seconds\n", $end - $start - $etime;
$start = $end;


print "  bp: refer       tocanon: ";

if ($save_hash) {
  foreach $hash ( @savehash ) {
    %can = &bib'tocanon(%$hash);
  }
} else {
  foreach (@rec) {
     %can = &bib'tocanon(&bib'explode($_));
  }
}
$end = (times)[0];
printf " %5.2f seconds\n", $end - $start - $etime;
$start = $end;


print "  bp: refer  tocanon(ncs): ";

&bib'options('csconv=false');
if ($save_hash) {
  foreach $hash ( @savehash ) {
    %can = &bib'tocanon(%$hash);
  }
} else {
  foreach (@rec) {
     %can = &bib'tocanon(&bib'explode($_));
  }
}
&bib'options('csconv=true');
$end = (times)[0];
printf " %5.2f seconds\n", $end - $start - $etime;
$start = $end;

}
print "\n";

if ($btx_test) {

print "  bp: bibtex         read: ";

&bib'format("bibtex");
&bib'open($bfile);
$i = 0; @rec = (); @savehash = ();
while ($record = &bib'read) {
  $rec[$i++] = $record;
}
&bib'close;
$end = (times)[0];
printf " %5.2f seconds  ($i records)\n", $end - $start;
$start = $end;

print "  bp: bibtex      explode: ";

if ($save_hash) {
  while (@rec) {
    push @savehash, { &bib'explode(shift @rec) };
  }
} else {
  foreach (@rec) {
    undef %ent;
    %ent = &bib'explode($_);
  }
}
$end = (times)[0];
$etime = $end - $start;
printf " %5.2f seconds\n", $etime;
$start = $end;

$etime = 0 if $save_hash;

print "  bp: bibtex      implode: ";

if ($save_hash) {
  foreach $hash ( @savehash ) {
    $irec = &bib'implode(%$hash);
  }
} else {
  foreach (@rec) {
    %can = &bib'implode(&bib'explode($_));
  }
}
$end = (times)[0];
printf " %5.2f seconds\n", $end - $start - $etime;
$start = $end;

print "  bp: bibtex      tocanon: ";

if ($save_hash) {
  foreach $hash ( @savehash ) {
    %can = &bib'tocanon(%$hash);
  }
} else {
  foreach (@rec) {
    %can = &bib'tocanon(&bib'explode($_));
  }
}
$end = (times)[0];
printf " %5.2f seconds\n", $end - $start - $etime;
$start = $end;

print "  bp: bibtex tocanon(ncs): ";

&bib'options('csconv=false');
if ($save_hash) {
  foreach $hash ( @savehash ) {
    %can = &bib'tocanon(%$hash);
  }
} else {
  foreach (@rec) {
     %can = &bib'tocanon(&bib'explode($_));
  }
}
&bib'options('csconv=true');
$end = (times)[0];
printf " %5.2f seconds\n", $end - $start - $etime;
$start = $end;

}

