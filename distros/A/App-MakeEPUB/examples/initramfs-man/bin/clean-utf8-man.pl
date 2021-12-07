#!/usr/bin/perl
#
# This cleans up man pages for use with rman.
# This means converting from utf8 to latin1 too.
#
use 5.010;
use strict;
use warnings;

binmode(STDIN,':utf8');
binmode(STDOUT,':raw');

my $concat = '';

while (<>) {
    if ($concat) {
	s/^\s*//;
	$_ = $concat . $_;
	$concat = '';
    }
    if (/\x{2010}\s*$/) {   # hyphen at end of line
        s/\x{2010}\s*$//;
	$concat = $_;
	next;
    }
    s/\x{00b1}/\x{b1}/g;    # plusminus
    s/\x{00b7}/*/g;	    # middle dot
    s/\x{2012}/-/g;	    # figure dash
    s/\x{2014}/-/g;	    # em dash
    s/\x{2018}/'/g;	    # left single quotation mark
    s/\x{2019}/'/g;	    # right single quotation mark
    s/\x{201c}/"/g;	    # left double quotation mark
    s/\x{201d}/"/g;	    # right double quotation mark
    s/\x{27e8}/</g;	    # mathematical left angle bracket
    s/\x{27e9}/>/g;	    # mathematical right angle bracket
    print;
}

__END__
