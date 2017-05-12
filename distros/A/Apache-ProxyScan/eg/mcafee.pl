#!/usr/bin/perl

# Copyright (c) 2002 Oliver Paukstadt. All rights reserved.
# This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.

# wrapper for mcafee
# http://www.nai.com/

$file = shift @ARGV;

#if (defined $ENV{'SCAN_TMP'}) {
#  $ENV{'_TMP'}=$ENV{'SCAN_TMP'};
#}

open(FH, "ulimit -t60 ; /usr/local/bin/uvscan --exit-on-error --summary --noexpire --mime --unzip --delete --secure '$file' |");
@msg = <FH>;
close FH;
$rc = $?;

if ($rc != 0) {
  $url = $ENV{'REQUEST_URI'};
  print "Content-type: text/html\n\n";
  print "<html><head><title>Virus Found</title></head><body>\n";

  print "<H1>Virus Alert!</H1>";
  print "while scanning <b>$url</b><br>\n";
  print "McAfee (return code $rc) reported:<br><PRE>".join("", @msg)."</PRE>\n";   

  print "</CODE></body>\n</HTML>";
  unlink "$file";
}

exit 1 if ($rc != 0);

