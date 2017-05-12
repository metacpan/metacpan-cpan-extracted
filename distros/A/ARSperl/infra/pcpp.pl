#!/usr/local/bin/perl
#
# $Header: /cvsroot/arsperl/ARSperl/infra/pcpp.pl,v 1.2 2000/08/31 02:12:05 jcmurphy Exp $
#
# pcpp.pl
#
# pre-cpp. 
#
# activestate perl defines some perl functions as macros,
# which generally complicates compilation for us. so we'll
# fiddle with our macros to try and work around their hackery.

while(<>) {
	s/VNAME\(([^\)]+)\)/ $1, strlen\($1\) /g;
	print;
}

exit 0;
