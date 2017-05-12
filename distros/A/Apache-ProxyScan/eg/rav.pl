#!/usr/bin/perl

# Copyright (c) 2002 Oliver Paukstadt. All rights reserved.
# This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.

# wrapper for rav
# http://www.ravantivirus.com/

use Expect;
$timeout = 60;

$file = shift @ARGV;
if (-z $file) { exit 0; }

#if (defined $ENV{'SCAN_TMP'}) {
#  $ENV{'RAV_TMP'}=$ENV{'SCAN_TMP'};
#}

my $scan = new Expect;
$scan->log_stdout(undef);
$scan->spawn("/opt/rav/bin/ravav", ("--all", "--archive", "--mail", "--heuristics=on", "$file")) or die "Cannot spawn $command: $!\n";

$scan->expect($timeout, undef);
$rc = $scan->exitstatus();
#print "RetrunCode: $rc\n";

$msg = $scan->before();
$scan->soft_close();

#print "RetrunCode: $rc\n";
$rc8 = $rc >> 8;

if ($rc8 != 1) {
  $url = $ENV{'REQUEST_URI'};
  print "Content-type: text/html\n\n";
  print "<html><head><title>Virus Found</title></head><body>\n";

  print "<H1>Virus Alert!</H1>";
  print "while scanning <b>$url</b><br>\n";
  $rm = returncode($rc8);
  print "RAV (return code $rc) reported: $rm<br><PRE>$msg</PRE>\n";   

  print "</CODE></body>\n</HTML>";
  unlink "$file";
}

exit 1 if ($rc8 != 1);
exit 0;

sub returncode {
  my $rc = shift @_;
  my %codes = ("1" => "The file is clean.",
            "2" => "Infected file.",
            "3" => "Suspicious file.",
            "4" => "The file was cleaned.",
            "5" => "Clean failed.",
            "6" => "The file was deleted.",
            "7" => "Delete failed.",
            "8" => "The file was successfully copied to quarantine.",
            "9" => "Copy failed.",
            "10" => "The file was successfully moved to quarantine.",
            "11" => "Move failed.",
            "12" => "The file was renamed.",
            "13" => "Rename failed.",
            "20" => "No TARGET is defined.",
            "30" => "Engine error.",
            "31" => "Syntax error.",
            "32" => "Help message.",
            "33" => "Viruses list.",
            "34" => "The updating process was successfully completed.",
            "35" => "The updating process failed.",
            "36" => "Already updated.",
            "37" => "The licensing process was successfully completed.",
            "38" => "The licensing process failed."
 );
  return scalar $codes{$rc};
}

 
