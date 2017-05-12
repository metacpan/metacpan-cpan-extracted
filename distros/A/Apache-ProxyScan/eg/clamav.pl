#!/usr/bin/perl

# Copyright (c) 2002 Oliver Paukstadt. All rights reserved.
# This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.

# wrapper for clamav
# http://clamav.elektrapro.com/

$file = shift @ARGV;

$optd='';
if (defined $ENV{'SCAN_TMP'}) {
  $optd="--tempdir=".$ENV{'SCAN_TMP'};
} 

open(FH, "ulimit -t60 ; /usr/bin/clamscan --mbox --threads=0 $optd --remove --stdout --disable-summary '$file' |");
@msg = <FH>;
close FH;
$rc = $?;

if ($rc != 0) {
  $url = $ENV{'REQUEST_URI'};
  print "Content-type: text/html\n\n";
  print "<html><head><title>Virus Found</title></head><body>\n";

  print "<H1>Virus Alert!</H1>";
  print "while scanning <b>$url</b><br>\n";
  print "clamscan (return code $rc) reported:<br><PRE>".join("", @msg)."</PRE>\n";   

  print "</CODE></body>\n</HTML>";
  unlink "$file";
}

exit 1 if ($rc != 0);

