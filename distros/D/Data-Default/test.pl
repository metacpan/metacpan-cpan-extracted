#!/usr/bin/perl -w
use strict;
# use Debug::ShowStuff ':all';
use Data::Default ':all';
use Test;
BEGIN { plan tests => 1 };


# variables
my ($str);

if (default $str, 1) {
	ok(1);
}
else {
	print STDERR "error: should have gotten 1\n";
	ok(0);
}



###############################################################################


#------------------------------------------------------------------------------
# check_ok
#
sub check_ok {
	my ($bool, $text) = @_;
	
	# if sucess
	if ($bool) {
		ok(1);
	}
	else {
		print STDERR "ERROR: $text\n";
		ok(0);
	}
}
#
# check_ok
#------------------------------------------------------------------------------
