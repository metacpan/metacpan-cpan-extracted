#!/usr/bin/perl
#
#  printenv—demo CGI program which just prints its environment
#
#
print "Content-Type: text/html; charset=ISO-8859-1\n\n";
foreach $var (sort(keys(%ENV))) {
    $val = $ENV{$var};
    $val =~ s/\n/\\n/g;
    $val =~ s/"/\\"/g;
    print "${var}=\"${val}\" <br />\n";
}
