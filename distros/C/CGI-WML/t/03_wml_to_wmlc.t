#!/usr/bin/perl

BEGIN { $| = 1; print "1..3\n"; }
END {print "not ok 1\n" unless $loaded;}
use CGI::WML;
$loaded = 1;
print "ok 1\n";

$q = CGI::WML->new;
open(IN,"t/test.html") || die ("Can't find test.html: $!\n");
while (<IN>) {$buffer .= $_;}
close (IN);

($title,$wml) = $q->html_to_wml($buffer);

$title =~ /Document Title/ && print "ok 2\n";

$wml =~ s/\>/\>\n/g;

if  ($CGI::WML::USEXMLPARSER == 1) {
    $wml = $q->card(-id=>"test",
                    -title=>$title,
                    -content=>$wml);

    $wmlc = $q->wml_to_wmlc( -wml=>$wml,
                             -errorcontext=>1);
    (defined $wmlc) && print "ok 3\n";
}else{
    print "ok 3 # Skip\n";
}

