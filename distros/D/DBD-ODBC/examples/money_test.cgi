#!c:/programme/perl/bin/perl.exe -w
# $Id$


use strict;				# activate for programming/debugging only
use warnings;				# activate for programming/debugging only
use CGI::Carp qw(fatalsToBrowser);	# activate for programming/debugging only

use CGI 'param','redirect';
use DBI;

# config variables
our $dsn='dsn';				# Database DSN
our $dbuser='user';			# Database User
our $dbpass='pass';			# Database Password
our $dbtable='test1';			# ProvTable

#################################################################################################

$|=1;

my $dbh = DBI->connect("DBI:ODBC:$dsn", $dbuser, $dbpass, { Taint =>1 }) || die "$DBI::errstr";
$dbh->{RaiseError} = 1;		# activate for programming/debugging only
$dbh->{PrintError} = 1;		# activate for programming/debugging only
$dbh -> {LongReadLen} = 100000;
$dbh -> {LongTruncOk} = 0;
#$dbh -> {odbc_default_bind_type} = 12; # SQL_VARCHAR


my $action=param('ACTION') || '';
if ($action=~/[^\w]/) { die "bad chars in parameter!" }

if	($action eq 'SAVE_PROV')	{&save_prov;}
else 					{&prov;}


sub prov {
	print "content-type: text/html\n\n";

	print "<Html><Head><Title>Title</Title></Head>\n";
	print "<BODY><CENTER><BR><BR>\n\n\n";
	print "<FORM NAME=A ACTION=money_test.cgi METHOD=POST><INPUT TYPE=HIDDEN NAME=ACTION VALUE=SAVE_PROV><TABLE BORDER=0 BGCOLOR=#DDDDDD>\n";
	print "<TR><TD><B>&nbsp;Text&nbsp;</B></TD><TD><B>&nbsp;Level1&nbsp;</B></TD><TD><B>&nbsp;Level2&nbsp;</B></TD><TD>&nbsp;</TD></TR>\n";

	# MsSQL
	my $sth0 = $dbh->prepare("
				SELECT 
					ISNULL(TypeName,'') AS TypeName,
					ISNULL(ProvLevel1,0.00) AS ProvLevel1,
					ISNULL(ProvLevel2,0.00) AS ProvLevel2,
					ISNULL(Action,0) AS Action
				FROM $dbtable with (NoLock) 
				ORDER BY Action
				");
	my $rv0 = $sth0->execute();
  	while (my $ref0 = $sth0->fetchrow_hashref()) {
		if ($ref0->{'Action'}==0) {
			print "<TR><TD>&nbsp;$ref0->{'TypeName'}&nbsp;</TD><TD>&nbsp;<INPUT TYPE=TEXT SIZE=5 NAME='LEVEL1_$ref0->{'TypeName'}' VALUE='$ref0->{'ProvLevel1'}'>&nbsp;</TD><TD>&nbsp;<INPUT TYPE=TEXT SIZE=5 NAME='LEVEL2_$ref0->{'TypeName'}' VALUE='$ref0->{'ProvLevel2'}'>&nbsp;</TD><TD>&nbsp;</TD></TR>\n";
		} else {
			print "<TR><TD>&nbsp;<b>V:</b> $ref0->{'TypeName'}&nbsp;</TD><TD>&nbsp;<INPUT TYPE=TEXT SIZE=5 NAME='LEVEL1_$ref0->{'TypeName'}' VALUE='$ref0->{'ProvLevel1'}'>&nbsp;</TD><TD>&nbsp;<INPUT TYPE=TEXT SIZE=5 NAME='LEVEL2_$ref0->{'TypeName'}' VALUE='$ref0->{'ProvLevel2'}'>&nbsp;</TD><TD>&nbsp;</TD></TR>\n";
		}
	}
	$sth0->finish();

	print "</TABLE><BR><BR><INPUT TYPE=SUBMIT VALUE='Save'></FORM>";
	print "</CENTER></BODY></HTML>";
}#///


sub save_prov {
				
	my $sth8 = $dbh->prepare("SELECT ISNULL(TypeName,'') AS TypeName FROM $dbtable with (NoLock)"); # MsSQL
	my $rv8 = $sth8->execute();
  	while (my $ref8 = $sth8->fetchrow_hashref()) {
			my $name=$ref8->{'TypeName'};
			my $level1=param("LEVEL1_$name") || '0';
			   $level1=~s/\,/\./i;
			   $level1=~s/[^\d.]//i;
			my $level2=param("LEVEL2_$name") || '0';
			   $level2=~s/\,/\./i;
			   $level2=~s/[^\d.]//i;
			
			# MsSQL
			my $sth9 = $dbh->prepare("
						UPDATE 
							$dbtable 
						SET 
							ProvLevel1=CONVERT(money,?),
							ProvLevel2=CONVERT(money,?) 
						WHERE TypeName=?
					");
			my $rv9=$sth9->execute($level1,$level2,$name);
			#$sth9->bind_param(n,undef,SQL_VARCHAR); # tell DBD-ODBC this is a char
			#$sth9->finish();
	}
	$sth8->finish();

	my $location="./money_test.cgi";
	print redirect(-uri=>$location);
	print "Content-Type: text/html\n";
	print "\n";
	print "<HTML><HEAD><TITLE>Redirect</TITLE></HEAD><BODY>";
	print "If your browser does not support redirection, please click ";
	print "<A HREF=\"$location\">here</A>";
	print "</BODY></HTML>";
}#///

$dbh->disconnect();
