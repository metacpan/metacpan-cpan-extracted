#!/usr/local/bin/perl -T
# 
# passwd_srv.pl - Apache::AuthenPasswdSrv password server for NIS
# Version: 0.01 (Alpha release)
#
# Written by Jeffrey Hulten <jeffh@premier1.net>
#
# May be used under the GPL version 2 or later.
#
# $Id: $
#

use strict;
use Socket;
use Net::NIS;
use Sys::Syslog;
use Carp;

my $VERSION = "0.1.0";

my $YPMATCH_PATH = '/usr/bin';
my $NAME = '/tmp/pswdsock';
my $uaddr = sockaddr_un($NAME);
my $proto = getprotobyname('tcp');
my $waitedpid = 0;
my $paddr;
my $domain = &Net::NIS::yp_get_default_domain();


$ENV{'PATH'} = "/usr/bin";
$ENV{'CDPATH'} = "" if ($ENV{'CDPATH'} ne "");
$ENV{'ENV'} = "" if ($ENV{'ENV'} ne "");

openlog "$0 {$domain}", 'pid, cons, nowait', 'auth';
 
sub spawn; # forward declaration
sub logmsg { syslog(shift @_, shift @_, @_);  }

socket(Server,PF_UNIX,SOCK_STREAM,0)   or die "socket: $!";
unlink($NAME);
bind(Server,$uaddr)                    or die "bind: $!";
listen(Server,SOMAXCONN)               or die "listen: $!";

logmsg('info', "server started on $NAME as $</$>");

$SIG{CHLD} = \&REAPER;

for ( ; $paddr = accept(Client,Server); close Client) 
{
	logmsg('info', "connection on $NAME");
	spawn sub 
	{
		
		my ($user, $passwd);
		my @pwent;
	
		print "211 Authentication Server (ver. $VERSION)\n";
		print "220 <$domain> Service ready\n";
			
		$_ = <STDIN>;
		
		chomp;
		if ($_ =~ /^(\S+) (\S+)$/) 
		{
			$user = $1;
			$passwd = $2;
		} 
		else 
		{
			print "501 Syntax error in parameters or arguments\n";
			print "221 <$domain> Service closing transmission channel\n";
			logmsg('notice',"Syntax error in parameters or arguments");
			closelog();
			return;
		}
		
		my($status, $value) = &Net::NIS::yp_match($domain, 'passwd.byname', $user); 
		unless (&nis_err_chk($status)) { print "221 <$domain> Service closing transmission channel\n"; return; }

		my($pvalue) = `$YPMATCH_PATH/ypmatch $user passwd.adjunct.byname`;

#		TODO : Fix this to use Net::NIS.  Check mailing list...
#		my($pstatus, $pvalue) = &Net::NIS::yp_match($domain, 'passwd.adjunct.byname', $user); 
#		print "100 $pstatus\n";
#		print "101 " . &Net::NIS::yperr_string($pstatus) . "\n";
#		print "102 $pvalue\n";
#		unless (&nis_err_chk($pstatus)) { print "221 <$domain> Service closing transmission channel\n"; return; }
		
		@pwent = split(':',$pvalue);

		# pull salt from crypt()
		my $salt = substr ($pwent[1], 0, 2);

		my $chkpasswd = crypt($passwd, $salt);
		if ($chkpasswd ne $pwent[1]) {
			print "401 Authentication failed for user $pwent[0]\n";
			print "221 <$domain> Service closing transmission channel\n";
			logmsg('notice',"Authentication failed for user $pwent[0]");
		} else {
			print "200 OK " . $value . "\n";
			print "221 <$domain> Service closing transmission channel\n";
			logmsg('info',"User $pwent[0] authenticated.");
		}
		closelog();
	};
}

closelog();

sub nis_err_chk {
	my $rcode = shift;
	if ($rcode == $Net::NIS::YP_SUCCESS) {
		return(1);
	}

	if ($rcode == $Net::NIS::ERR_ACCESS) 	{ print "403 Access violation\n"; }	
	elsif ($rcode == $Net::NIS::ERR_KEY) 	{ print "404 No such key in map\n"; }	
	elsif ($rcode == $Net::NIS::ERR_BADARGS){ print "501 Args to function are bad\n"; }	
	elsif ($rcode == $Net::NIS::ERR_BADDB) 	{ print "502 YP data base is bad\n"; }	
	elsif ($rcode == $Net::NIS::ERR_BUSY) 	{ print "503 Database is busy\n"; }	
	elsif ($rcode == $Net::NIS::ERR_DOMAIN) { print "504 Can't bind to a server which serves this domain\n"; }	
	elsif ($rcode == $Net::NIS::ERR_MAP) 	{ print "505 No such map in server's domain\n"; }	
	elsif ($rcode == $Net::NIS::ERR_NODOM) 	{ print "506 Local domain name not set\n"; }	
	elsif ($rcode == $Net::NIS::ERR_NOMORE) { print "507 No more records in map database\n"; }	
	elsif ($rcode == $Net::NIS::ERR_RESRC) 	{ print "508 Local resource allocation failure\n"; }	
	elsif ($rcode == $Net::NIS::ERR_PMAP) 	{ print "510 Can't communicate with portmapper\n"; }	
	elsif ($rcode == $Net::NIS::ERR_RPC) 	{ print "511 RPC failure\n"; }	
	elsif ($rcode == $Net::NIS::ERR_YPBIND) { print "512 Can't communicate with ypbind\n"; }	
	elsif ($rcode == $Net::NIS::ERR_YPERR) 	{ print "513 Internal yp server or client interface error\n"; }	
	elsif ($rcode == $Net::NIS::ERR_YPSERV) { print "514 Can't communicate with ypserv\n"; }	
	elsif ($rcode == $Net::NIS::ERR_VERS) 	{ print "515 YP version mismatch\n"; }	
	else 					{ print "599 Unknown NIS error\n"; }
		
	logmsg('err',"Server error: " . &Net::NIS::yperr_string($rcode));
	closelog();
	return(0);	
		
}

sub REAPER 
{
	$waitedpid = wait;
	$SIG{CHLD} = \&REAPER;
	logmsg('info', "reaped $waitedpid" . ($? ? " with exit $?" : ""));
}

sub spawn 
{
	my $coderef = shift;
	
	unless (scalar(@_) == 0 && $coderef && ref($coderef) eq 'CODE') 
	{
		my $msg = "useage: spawn CODEREF ";
		$msg .= "(\@_ Mismatch \@_ = (" . join(' ',@_) . ")) " if (scalar(@_) != 0);
		$msg .= "(\$coderef = $coderef) " if (!$coderef);
		$msg .= "(ref eq ". ref($coderef) .")" if (ref($coderef) ne 'CODE');
		confess $msg;
	}
	
	my $pid;
	if (!defined($pid = fork)) 
	{
		logmsg('err', "cannot fork: $!");
		return;
	} 
	elsif ($pid) 
	{
		logmsg('info', "begat $pid");
		return; # i am the parent
	}
	
	open(STDIN, "<&Client")  or die "can't dup client to stdin";
	open(STDOUT, ">&Client")  or die "can't dup client to stdout";

	select(STDOUT); $| = 1;

	exit &$coderef();
}
	
	





