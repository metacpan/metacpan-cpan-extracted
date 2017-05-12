#!/usr/bin/perl
# check.pl - Makefile helper utility to make perl wrapper for CLucene
# usage: check.pl -> checks that SWIG is 1.3 or later or gives an error
# usage: check.pl -perl -> prints location of perl CORE directory
# usage: check.pl -os -> prints operating system e.g. linux
#
# Copyright(c) 2005 Peter Edwards <peterdragon@users.sourceforge.net>
# All rights reserved. This package is free software; you can redistribute
# it and/or modify it under the same terms as Perl itself.

use warnings;
use strict;

use Config;
use Carp;

my $instarchlib = $Config{installarchlib};
my $PERLCORE="$instarchlib/CORE";
if ( $#ARGV >= 0 && $ARGV[0] eq "-perl" )
{
	print $PERLCORE;
	exit(0);
}
if ( $#ARGV >= 0 && $ARGV[0] eq "-os" )
{
	print "$^O";
	#my $UNAME=`uname -s`;
	#my $REDHATVER=`rpm -q redhat-release`;
	#if ( $REDHATVER =~ m/^redhat-/ )
	#{
	#	print "redhat";
	#}
	#elsif ( $UNAME =~ m/^Linux/ )
	#{
	#	print "linux";
	#}
	#elsif ( $UNAME =~ m/^CYGWIN/i )
	#{
	#	print "cygwin";
	#}
	#else
	#{
	#	print "unknown";
	#}
	exit(0);
}
if ( $#ARGV >= 0 && $ARGV[0] eq "-osver" )
{
	my $UNAME=`uname -s`;
	my $REDHATVER=`rpm -q redhat-release`;
	if ( $REDHATVER =~ m/^redhat-release-9-/ )
	{
		print "rh9";
	}
	elsif ( $REDHATVER =~ m/redhat-release-3ES-/ )
	{
		print "rhel3";
	}
	elsif ( $REDHATVER =~ m/redhat-release-4ES-/ )
	{
		print "rhel4";
	}
	elsif ( $UNAME =~ m/^Linux/ )
	{
		print "linux";
	}
	elsif ( $UNAME =~ m/^CYGWIN/i )
	{
		print "cygwin";
	}
	else
	{
		print "unknown";
	}
	exit(0);
}

print "checking versions...\n";

my $swigver = "unknown";
CORE::system("swig -version > swig.ver 2>&1");
open(FH,"<swig.ver") || confess "$!";
while (my $line = <FH>)
{
	if ( $line =~ m/^SWIG Version / )
	{
		$line =~ s/^SWIG Version //;
		chomp $line;
		$swigver = $line;
	}
}
close(FH);

print "  perl core    : $PERLCORE\n";
print "  swig version : $swigver\n";

no warnings 'numeric';
if ( $swigver < "1.3" )
{
	print <<EOM ;
ERROR: you need to use swig version 1.3 or later, you have $swigver
Download a later version from www.swig.org, install it and make
sure that when you type 'swig' it runs the later version.
You could do this by installing swig to below /usr/local and then
typing "export PATH=/usr/local/bin:\$PATH" before running "make"
EOM
	exit(1);
}
print "  OK\n";

exit(0);
