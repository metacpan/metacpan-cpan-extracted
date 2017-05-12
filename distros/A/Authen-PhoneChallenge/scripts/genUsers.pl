#!/usr/bin/perl
use warnings;
use strict;
use Carp;

# Usage: genUsers.pl <numUsers> <numCodes> [userOffset]

my $numUsers = shift || croak('must pass number of users');
my $numCodes = shift || croak('must pass number of codes');
my $userOffset = shift || 100;


print <<EOF;
<?xml version="1.0"?>
<users>
EOF


for(my $i = 0; $i < $numUsers; $i++)
{
	print "\t<user id=\"", $i + $userOffset, "\">\n";

	for(my $j = 0; $j < $numCodes; $j++)
	{
		my $code = sprintf "%05d", int(rand(10000));
		print "\t\t<token challenge=\"$j\" response=\"$code\" used=\"0\"/>\n";
	}

	print "\t</user>\n";
}


print "</users>\n";
