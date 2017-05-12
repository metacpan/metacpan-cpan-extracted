package Apache::HTTunnel::Keeper ;

use strict ;
use File::FDkeeper ;
use IO::Pipe ;
use Apache2::ServerUtil ;
use Apache2::Directive ;
use Apache2::Log ;


# Get configuration info from the Apache config file.
my $s = Apache2::ServerUtil->server() ;
my $slog = $s->log() ;
my $tree = Apache2::Directive::conftree() ;
my $apache_user = $tree->lookup('User') ;
my $apache_uid = getpwnam($apache_user) ;
my $apache_group = $tree->lookup('Group') ;
my $apache_gid = getgrnam($apache_group) ;
my $fifo = $s->dir_config('HTTunnelFifo') or die("HTTunnelFifo not defined in Apache configuration file") ;
my $conn_timeout = $s->dir_config('HTTunnelConnectionTimeout') || 900 ;


# Setup File::FDkeeper 
$slog->info("HTTunnel Keeper: Creating File::FDkeeper\@$fifo...") ;
my $fdk = new File::FDkeeper(
	Local => $fifo,
	AccessTimeout => $conn_timeout,
	AccessTimeoutCheck => 15,
) ;
$slog->notice("HTTunnel Keeper: File::FDkeeper\@$fifo created") ;

# Setup proper permissions on the fifo...
if (($apache_user)||($apache_group)){
	if (! defined($apache_uid)){
		$apache_uid = -1 ;
	}
	if (! defined($apache_gid)){
		$apache_gid = -1 ;
	}

	$slog->debug("HTTunnel Keeper: Apache User is '$apache_user' ($apache_uid)") ;
	$slog->debug("HTTunnel Keeper: Apache Group is '$apache_group' ($apache_gid)") ;
	chown($apache_uid, $apache_gid, $fifo) or die("Can't chown '$fifo': $!") ;
	chmod(0600, $fifo) or die("Can't chmod '$fifo': $!") ;
}


# Now that everything is all set, we can fork and let the child do the work.
my $lifeline = new IO::Pipe() ;
my $pid = fork() ;
die("Can't fork: $!") unless defined($pid) ;
if ($pid){
	# parent
	$slog->notice("HTTunnel Keeper: Keeper process forked, pid is $pid") ;

	$lifeline->writer() ;

	# Store a reference to the lifeline in a global variable so that it 
	# lives on past this scripts scope...
	$Apache::HTTunnel::Keeper::LIFELINE = $lifeline ;
}
else {
	# child
	$lifeline->reader() ;
	$slog->notice("HTTunnel Keeper: Entering main loop") ;
	$fdk->run($lifeline) ;
	$slog->notice("HTTunnel Keeper: Main loop terminated") ;
}



1 ;
