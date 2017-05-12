#!/usr/bin/perl -w
#########################################
#
# Burpsuite::Parser v0.1 example script 
#
#########################################
use strict;
use Burpsuite::Parser;
use vars qw( $PROG );
( $PROG = $0 ) =~ s/^.*[\/\\]//;    # Truncate calling path from the prog name
my $bparser = new Burpsuite::Parser;
my $file;
sub usage {
    print "usage: $0 [file.xml]\n";
    exit;
}
if ( $ARGV[0] ) {
    $file = $ARGV[0];
}
else {
    usage;
}

my $parser = $bparser->parse_file("$file");
foreach my $h ( $parser->get_all_issues() ) {
    print $h->name . "\n";
    print "Severity: " . $h->severity . "\n\n";
    print "Description: \n" . $h->issue_background . "\n";
    print "Proof of Concept: \n" . $h->issue_detail . "\n";
    print "Recommendation: \n" . $h->remediation_background . "\n";
    print "\n-----------\n\n";
}
