#!/usr/bin/perl

BEGIN { $| = 1; print "1..3\n"; }
END {print "not ok 1\n" unless $loaded;}
use CGI::WML;
$loaded = 1;
print "ok 1\n";

$q = CGI::WML->new;
open(IN,"t/test.html") || die ("Can't find test.html: $!\n");
($title,$wml) = $q->html_to_wml(-html=>\*IN,
                                -linkbreaks=>1);
close (IN);
defined $wml && print "ok 2\n";

open(IN,"t/test.html") || die ("Can't find test.html: $!\n");
while(<IN>) {$buffer .= $_;}
close(IN);
($title,$wml) = $q->html_to_wml(-html=>$buffer,
                                -linkbreaks=>1);

defined $wml && print "ok 3\n";

