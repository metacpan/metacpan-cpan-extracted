#!/usr/bin/perl

$cut  = "/usr/bin/cut";
$grep = "/usr/bin/grep";
$sort = "/usr/bin/sort";
$diff = "/usr/bin/diff";

system "$grep '^sub ' lib/Apache/Logmonster.pm | $cut -f2 -d' ' | $sort > t/tmp_subs";
system "$grep '^## '  t/Logmonster.t | $cut -f2 -d' ' | $sort -u > t/tmp_tests";

#print "          the following subs are missing tests\n";
system "$diff --suppress-common-lines t/tmp_subs t/tmp_tests";
