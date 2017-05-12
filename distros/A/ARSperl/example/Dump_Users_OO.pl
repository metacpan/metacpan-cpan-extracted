#!/usr/local/bin/perl -w
#
# $Header: /cvsroot/arsperl/ARSperl/example/Dump_Users_OO.pl,v 1.3 2007/03/13 13:20:32 jeffmurphy Exp $
#
# NAME
#   Dump_Users_OO.pl [server] [username] [password]
#
# DESCRIPTION
#   Example of Object Oriented programming layered on top of ARSperl
#
# AUTHOR
#   Jeff Murphy
#
# $Log: Dump_Users_OO.pl,v $
# Revision 1.3  2007/03/13 13:20:32  jeffmurphy
# minor update to example scripts
#
# Revision 1.2  1999/05/26 03:42:46  jcmurphy
# minor change to exception handler
#
# Revision 1.1  1999/05/05 19:57:40  rgc
# Initial revision
#

use strict;
use ARS;
require Carp;

sub mycatch { 
  my $type = shift;
  my $msg = shift;
  my $trace = shift;

  print "i caught an exception:\ntype=$type msg=$msg\ntraceback:\n$trace\n"; 
  exit;
}

my $LoginNameField = "Login name"; # earlier versions of ars used "Login Name"

my $connection = new ARS (-server   => shift,
			  -username => shift, 
			  -password => shift,
			  -catch => { ARS::AR_RETURN_ERROR => "main::mycatch" },
			  -ctrl => undef,
			  -debug => undef);

print "Opening \"User\" form ..\n";

my ($u) = $connection->openForm(-form => "User");

$u->setSort($LoginNameField, &ARS::AR_SORT_ASCENDING);

my @entries = $u->query(); # empty query means "get everything"

printf("%-30s %-45s\n", $LoginNameField, "Full name");
foreach my $id (@entries) {
  my($fullname, $loginname) = $u->get($id, ['Full Name', $LoginNameField] );
  printf("%-30s %-45s\n", $loginname, $fullname);
}



exit 0;
