#!/usr/local/bin/perl
#
# $Header: /cvsroot/arsperl/ARSperl/example/ars_ExecuteProcess.pl,v 1.3 2009/03/31 13:34:32 mbeijen Exp $
#
# NAME
#   ars_ExecuteProcess.pl
#
# USAGE
#   ars_ExecuteProcess.pl [server] [username] [password] ["process"]
#    if you need to use a specified TCP port, export the ARTCPPORT environment variable
#    with the TCP Port number
#
# EXAMPLE
#   ars_ExecuteProcess.pl arserver user password "ls -l /" (if the server is on Unix)
#  ars_ExecuteProcess.pl arserver user password " cmd /c dir" (if the server is on Win32)
#  ars_ExecuteProcess.pl arserver user password Application-Generate-GUID
#
# DESCRIPTION
#   Execute given command on remote arserver. Requires admin account to work.
#
# AUTHOR
#   Jeff Murphy
#
# $Log: ars_ExecuteProcess.pl,v $
# Revision 1.3  2009/03/31 13:34:32  mbeijen
# Verified and updated examples.
# Removed ars_GetFullTextInfo.pl because ars_GetFullTextInfo is obsolete since ARS > 6.01
#
# Revision 1.2  2007/08/02 14:48:21  mbeijen
# modified examples for ExecuteProcess and decodeStatusHistory
#
# Revision 1.1  1997/07/23 18:21:29  jcmurphy
# Initial revision
#
#
#

use ARS;
use strict;

die "usage: ars_ExecuteProcess.pl server username \"string to execute\"\n"
  if ( $#ARGV < 3 );

my ( $server, $user, $pass, $command ) = ( shift, shift, shift, shift );

#Logging in to the server
( my $ctrl = ars_Login( $server, $user, $pass ) )
  || die "ars_Login: $ars_errstr";

( my ( $num, $str ) = ars_ExecuteProcess( $ctrl, $command ) )
  || print "ERR: $ars_errstr\n";
print "gotit: $ars_errstr\n";

print "returnCode=<$num> returnString=<$str>\n";

ars_Logoff($ctrl);
