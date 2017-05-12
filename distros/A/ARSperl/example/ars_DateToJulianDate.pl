#!/usr/local/bin/perl
#
# $Header: /cvsroot/arsperl/ARSperl/example/ars_DateToJulianDate.pl,v 1.1 2009/03/31 13:29:50 mbeijen Exp $
#
# NAME
#   ars_DateToJulianDate.pl
#
# USAGE
#   ars_DateToJulianDate.pl [server] [username] [password] [year] [ month]  [date]
#
# DESCRIPTION
#   Converts a year-month-date value to a JulianDate.
#
# AUTHOR
#  Michiel Beijen
#
# $Log: ars_DateToJulianDate.pl,v $
# Revision 1.1  2009/03/31 13:29:50  mbeijen
# added new examples: ChangePassword.pl, ars_DateToJulianDate.pl, getCharSets.pl
#
#

use ARS;
use strict;

die "usage: $0 server username password year month day\n"
  unless ( $#ARGV >= 5 );

my ( $server, $user, $password, $year, $month, $day, ) =
  ( shift, shift, shift, shift, shift, shift, );

#Logging in to the server
( my $ctrl = ars_Login( $server, $user, $password ) )
  || die "ars_Login: $ars_errstr";

print "Converting year $year month $month day $day to Julian...\n";

( my $juliandate = ars_DateToJulianDate( $ctrl, $year, $month, $day ) )
  || die "ERR: $ars_errstr\n";

ars_Logoff($ctrl);

print "The JulianDate value is $juliandate\n";
