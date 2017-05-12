#!/usr/bin/perl
#
#

# This script will decode a callerid string and print it in pretty form

use strict;
use warnings;

#use lib '/home/mcarr/Callerid/lib';
use Callerid;

while(<>) {
	if(m/([0-9a-fA-F]+)/) {
		my($cid) = new Callerid($1);
		my($format) = << "EOL";
%s => (
\t%20s => %s,
\t%20s => %s,
\t%20s => %02d/%02d %02d:%02d,
);
EOL
		printf $format,
			$1,
			'name', $cid->{name},
			'number', $cid->{number},
			'time', $cid->{month}, $cid->{day}, $cid->{hour}, $cid->{minute}
		;
	}
}
# vim: set foldmethod=marker:
