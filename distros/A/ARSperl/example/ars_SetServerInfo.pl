#!/usr/local/bin/perl
#
# $Header: /cvsroot/arsperl/ARSperl/example/ars_SetServerInfo.pl,v 1.1 2000/08/31 05:18:41 jcmurphy Exp $
#
# NAME
#   ars_SetServerInfo.pl
#
# USAGE
#   ars_SetServerInfo.pl [server] [username] [password] [emailAdd]
#
# DESCRIPTION
#   sets the "email from" address for the server. 
#

use ARS;

my $c = ars_Login(shift, shift, shift);
die "ars_Login: $ars_errstr\n" unless defined($c);

print "Fetching current EMAIL_FROM setting..\n";
my %il = ars_GetServerInfo($c,
			   &ARS::AR_SERVER_INFO_EMAIL_FROM);
print "\tEMAIL_FROM = $il{'EMAIL_FROM'}\n\n";
my $orig = $il{'EMAIL_FROM'};


print "Setting EMAIL_FROM to foo\@bar.com .. \n";
ars_SetServerInfo($c, 
		  &ARS::AR_SERVER_INFO_EMAIL_FROM,
		  "foo\@bar.com") ||
  die "ars_SetServerInfo: $ars_errstr\n";

print "\nFetching newly set EMAIL_FROM setting..\n";
my %il = ars_GetServerInfo($c,
			   &ARS::AR_SERVER_INFO_EMAIL_FROM);
print "\tEMAIL_FROM = $il{'EMAIL_FROM'}\n\n";


print "Setting EMAIL_FROM to original setting..\n";
ars_SetServerInfo($c, 
		  &ARS::AR_SERVER_INFO_EMAIL_FROM,
		  $orig) ||
  die "ars_SetServerInfo: $ars_errstr\n";

print "\nDone.\n";

exit 0;
