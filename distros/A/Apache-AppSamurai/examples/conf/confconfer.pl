#!/usr/bin/perl -wT

# $Id: confconfer.pl,v 1.3 2007/09/28 06:28:20 pauldoom Exp $

##
# Copyright (c) 2007 Paul M. Hirsch (paul@voltagenoir.org).
# All rights reserved.
#
# This program is free software; you can redistribute it and/or modify it under
# the same terms as Perl itself.
##
use strict;

use vars qw($VERSION);
$VERSION = substr(q$Revision: 1.3 $, 10, -1);

my $usage =<<"EOU";
>>> confconfer.pl - Fill out a sample config template to make a real config <<<
Usage: confconfer.pl INPUTFILE > OUTPUTFILE

1) Takes single argument which must be a plain text file containing one or
   more replacement variables as input.
2) Prompts for the value of each unique replacement variable.
3) Spits out the input with the replacement variables replaced.

Replacement variables are specified with the syntax: __VARIABLENAME__
For example, if this script encountered the line:

    <Directory "__DOCUMENTROOT__/junk">

and the user entered:

    /var/toad/master

confconfer would spit out the line:

   <Directory "/var/toad/master/junk">
 
This usage text is longer than the code itself.
EOU

my %v = ();
my $i = '';
my $o = '';

($ARGV[0]) or die "FATAL: You must specify an input template file\n$usage\n";
(-f $ARGV[0]) or die "FATAL: Missing or bad template file \"$ARGV[0]\": $!\n";
print STDERR "Opening \"$ARGV[0]\"...\n";
open(TF, "$ARGV[0]") or die "FATAL: Unable to open template file \"$ARGV[0]\": $!\n"; 
# Read in input and stow it
print STDERR "Reading in template...\n";
while ($_ = <TF>) {
    $i .= $_;
}
close(TF);

# Fill in the vars
print STDERR "Gathering replacement values from user (that means you):\n";
while ($i =~ s/^(.*?)__([^\s]+)__//s) {
    ($1) && ($o .= $1);
    $o .= fillOut($2);
}
$o .= $i; # Add remainder

# Out goes the output
print STDERR "Sending output to STDOUT...";
print STDOUT $o;
print STDERR "Done.\n";
exit 0;

# Check for template var, prompting for input if needed.  Returns template
# var value
sub fillOut {
    my $vn = shift;
    unless (exists($v{$vn})) {
	# Get velue, and don't accept empty...
	my $val = '';
	while ($val =~ /^\s*$/) {
	    print STDERR "Enter the value for \"$vn\" : ";
            $| = 1; # Flush to STDOUT
	    my $in = <STDIN>;
	    if (!defined($in) || $in =~ /^\s*$/) {
		print STDERR "Empty?  Please try again\n";
	    } else {
		$in =~ /^\s*(.+?)\s*$/; # Pull in value, sans surrounding white
		$val = $1;
	    }
	}
	$v{$vn} = $val;
    }

    return $v{$vn};
}
	    

