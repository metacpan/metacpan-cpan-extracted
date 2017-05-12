#!/usr/bin/perl -i
#
# @(#)$Id: setminref.pl,v 2015.3 2015/08/27 02:44:48 jleffler Exp $ 
#
# DBD::Informix for Perl Version 5
#
# Set minimum and current versions for Perl and DBI where they occur.
#
# Copyright 2015 Jonathan Leffler
#
# You may distribute under the terms of either the GNU General Public
# License or the Artistic License, as specified in the Perl README file.
#
# Key job: Substitute the minimum and reference versions of Perl and
#          DBI as specified in DBD::Informix::Configure into files.

use strict;
use warnings;
use lib 'lib';
use DBD::Informix::Configure;

my $DBI_MINVERSION = $DBD::Informix::Configure::DBI_MINVERSION;
my $DBI_REFVERSION = $DBD::Informix::Configure::DBI_REFVERSION;
my $PERL_MINVERSION = $DBD::Informix::Configure::PERL_MINVERSION;
my $PERL_REFVERSION = $DBD::Informix::Configure::PERL_REFVERSION;

if (scalar @ARGV)
{
    while (<>)
    {
        s/[:]DBI_MINVERSION:/$DBI_MINVERSION/g;
        s/[:]DBI_REFVERSION:/$DBI_REFVERSION/g;
        s/[:]PERL_MINVERSION:/$PERL_MINVERSION/g;
        s/[:]PERL_REFVERSION:/$PERL_REFVERSION/g;
        print;
    }
}
else
{
    print "DBI minimum version = $DBI_MINVERSION\n";
    print "DBI reference version = $DBI_REFVERSION\n";
    print "Perl minimum version = $PERL_MINVERSION\n";
    print "Perl reference version = $PERL_REFVERSION\n";
}
