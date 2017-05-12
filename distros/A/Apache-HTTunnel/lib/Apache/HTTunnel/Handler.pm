package Apache::HTTunnel::Handler ;

use strict ;
use File::FDkeeper ;
use Socket ;
use IO::Socket::INET ;
use Carp ;

use Apache2::RequestRec ;
use Apache2::RequestIO ;
use Apache2::RequestUtil ;
use Apache2::Response ;
use APR::Table ;
use Apache2::Const qw(:common :http) ;


my $fdk = undef ;


sub handler {
	my $r = shift ;

	my $slog = $r->log() ;

	if ($r->method() ne 'POST'){
		return Apache2::Const::HTTP_METHOD_NOT_ALLOWED() ;
	}
	my $code = OK ;
	my $resp = undef ;
	my $timeout = 0 ;
	my $extra = undef ;
	eval {
		if (! defined($fdk)){
			# Connect to the file descriptor storage process
			my $fifo = $r->dir_config('HTTunnelFifo') ;
			$slog->info("HTTunnel Handler: Creating File::FDkeeper\@$fifo...") ;
			$fdk = new File::FDkeeper(Peer => $fifo) ;
			$slog->notice("HTTunnel Handler: File::FDkeeper\@$fifo created") ;
		}

		# Now let's process the current request
		my $path_info = $r->path_info() ;
		$path_info =~ s/^\/// ;
		$path_info =~ s/\/$// ;
		my @params = split(/\//, $path_info) ;
	
		my $cmd = shift @params ;
		$slog->info("HTTunnel Handler: Processing '$cmd' command ($path_info)") ;
		if ($cmd eq 'connect'){
			($resp, $timeout, $extra) = connect_cmd($r, @params) ;
		}
		elsif ($cmd eq 'read'){
			($resp, $timeout, $extra) = read_cmd($r, @params) ;
		}
		elsif ($cmd eq 'write'){
			($resp, $timeout, $extra) = write_cmd($r, @params) ;
		}
		elsif ($cmd eq 'close'){
			($resp, $timeout, $extra) = close_cmd($r, @params) ;
		}
		else {
			die("Invalid command $cmd ($path_info)") ;
		}
	} ;
	if ($@){
		# TODO: Handle APR::Error
		$resp = 'err'. $@ ;
		$slog->error("HTTunnel Handler: $@") ;
	}
	else {
		if (defined($extra)){
			$extra .= ':' ;
		}
		if ($timeout){
			$resp = 'okt' . $extra ;
		}
		elsif (length($resp) == 0){
			$resp = 'okn' . $extra ;
		}
		else {
			$resp = 'okd' . $extra . $resp ;
		}
	}

	$r->print($resp) or
		$slog->error("HTTunnel Handler: Error writing response to client: $!") ;
	$r->rflush() ;

	my $cnt = $fdk->cnt() ;
	$slog->info("HTTunnel Handler: $cnt handles remaining in Keeper") ;

	return OK ;
}


sub connect_cmd {
	my $r = shift ;
	my @params = @_ ;

	my $slog = $r->log() ;
	my $proto = shift @params ;
	my $host = shift @params ;
	my $port = shift @params ;
	my $timeout = shift @params || 15 ;
	my $max_timeout = $r->dir_config('HTTunnelMaxConnectTimeout') || 15 ;
	if ($timeout > $max_timeout){
		$slog->notice("HTTunnel Handler: Requested connect timeout ($timeout) decreased " .
			"to HTTunnelMaxConnectTimeout ($max_timeout)") ;
		$timeout = $max_timeout ;
	}

	check_access($r, $host, $port) ;
	$slog->info("HTTunnel Handler: Connecting to $host:$port...") ;

	my $sock = undef ;
	my $peer_info = undef ;
	eval {
		local $SIG{ALRM} = sub {die "timeout\n"} ;
		alarm($timeout) ;
		$sock = new IO::Socket::INET(
			Proto => $proto,
			PeerAddr => $host,
			PeerPort => $port,
		) ;
		die("Error connecting to $host:$port: $!") unless defined($sock) ;

		if ($proto eq 'tcp'){
			my $peer = getpeername($sock) ;
			my ($port, $addr) = sockaddr_in($peer) ;
			$peer_info = join(':', inet_ntoa($addr), $port) ;
		}

		alarm(0) ;
	} ;
	if ($@){
		if ($@ eq "timeout\n"){
			$slog->notice("HTTunnel Handler: Connection to $host:$port timed out " .
				"after $timeout seconds.") ;
			return (undef, 0) ;
		}
		else {
			alarm(0) ;
			die("$@\n") ;
		}
	}

	die("Can't connect to $host:$port: $!") unless $sock ;
	$slog->notice("HTTunnel Handler: Connected to $host:$port") ;

	$slog->notice("HTTunnel Handler: Putting filehandle...") ;
	my $fhid = $fdk->put($sock) ;
	$slog->notice("HTTunnel Handler: Filehandle '$fhid' put") ;

	return ($fhid, 0, $peer_info) ;
}


sub check_access {
	my $r = shift ;
	my $host = shift ;
	my $port = shift ;

	my $slog = $r->log() ;
	my $rules = $r->dir_config('HTTunnelAllowedTunnels') or die("HTTunnelAllowedTunnels not defined in Apache configuration file") ;
	$rules =~ s/^\s+// ;
	$rules =~ s/\s+$// ;
	my @rules = split(/\s*,\s*/, $rules) ;
	foreach my $r (@rules){
		$slog->debug("HTTunnel Handler: Allowed (raw): $r") ;
	}

	my %allowed = () ;
	foreach my $r (@rules){
		my ($hosts, $ports) = split(/\s*=>\s*/, $r) ;
		my @hosts = split(/\s*\|\s*/, $hosts) ;
		my @ports = split(/\s*\|\s*/, $ports) ;

		foreach my $h (@hosts){
			foreach my $p (@ports){
				my @addrs = ($h) ;
				if ($h ne '*'){
					my @info = gethostbyname($h) ;
					for (my $i = 4 ; $i < scalar(@info) ; $i++){
						push @addrs, inet_ntoa($info[$i]) ;
					}
				}
				foreach my $a (@addrs){
					$allowed{"$a:$p"} = 1 ;
				}
			}
		}
	}
	foreach my $r (@rules){
		$slog->debug("HTTunnel Handler: Allowed (expanded): $r") ;
	}

	if (($allowed{"$host:$port"})||($allowed{"$host:*"})||
		($allowed{"*:$port"})||($allowed{"*:*"})){
		$slog->notice("HTTunnel Handler: $host:$port is allowed by configuration") ;
	}
	else{
		die("Permission denied for $host:$port") ;
	}
}


sub read_cmd {
	my $r = shift ;
	my @params = @_ ;

	my $slog = $r->log() ;
	my $fhid = shift @params ;
	my $proto = shift @params ;
	my $len = shift @params ;
	my $timeout = shift @params || 15 ;
	my $max_len = $r->dir_config('HTTunnelMaxReadLength') || 131072 ;
	if ($len > $max_len){
		$slog->notice("HTTunnel Handler: Requested read length ($len) decreased " .
			"to HTTunnelMaxReadLength ($max_len)") ;
		$len = $max_len ;
	}
	my $max_timeout = $r->dir_config('HTTunnelMaxReadTimeout') || 15 ;
	if ($timeout > $max_timeout){
		$slog->notice("HTTunnel Handler: Requested read timeout ($timeout) decreased " .
			"to HTTunnelMaxReadTimeout ($max_timeout)") ;
		$timeout = $max_timeout ;
	}

	my $data = undef ;
	$slog->notice("HTTunnel Handler: Getting filehandle '$fhid'...") ;
	my $fh = $fdk->get($fhid) or die("Unknown filehandle '$fhid'") ;
	$slog->notice("HTTunnel Handler: Filehandle '$fhid' gotten") ;

	my $timed_out = 0 ;
	my $peer_info = undef ;
	eval {
		local $SIG{ALRM} = sub {die "timeout\n"} ;
		alarm($timeout) ;
		$slog->info("HTTunnel Handler: Reading up to $len bytes from filehandle '$fhid'") ;
		if ($proto eq 'udp'){
			my $peer = undef ;
			($peer, $data) = recv_from($fh, $len) ;
			my ($port, $addr) = sockaddr_in($peer) ;
			$peer_info = join(':', inet_ntoa($addr), $port) ;
		}
		else{
			$data = read_from($fh, $len) ;
		}
		if (! defined($data)){
			$slog->notice("HTTunnel Handler: EOF detected on filehandle '$fhid'") ;
		}
		else {
			my $l = length($data) ;
			$slog->notice("HTTunnel Handler: Read $l bytes from filehandle '$fhid'") ;
		}

		alarm(0) ;
	} ;
	if ($@){
		if ($@ eq "timeout\n"){
			$slog->notice("HTTunnel Handler: Read timed out on purpose after $timeout seconds.") ;
			$timed_out = 1 ;
		}
		else {
			alarm(0) ;
			die("$@\n") ;
		}
	}

	return ($data, $timed_out, $peer_info) ;	
}


sub write_cmd {
	my $r = shift ;
	my @params = @_ ;

	my $slog = $r->log() ;
	my $fhid = shift @params ;
	my $proto = shift @params ;

	my $cl = $r->headers_in->{'Content-Length'} ;
	defined($cl) or die("Content-Length is not defined") ;
	$slog->notice("HTTunnel Handler: Content-Length is $cl bytes") ;
	my $data = '' ;

	$slog->notice("HTTunnel Handler: Getting filehandle '$fhid'...") ;
	my $fh = $fdk->get($fhid) or die("Unknown filehandle '$fhid'") ;
	$slog->notice("HTTunnel Handler: Filehandle '$fhid' gotten") ;


	my $left = $cl ;
	$slog->info("HTTunnel Handler: Reading $cl bytes from request input...") ;
	while ($left > 0){
		my $cnt = $r->read($data, $left) ;
		$cnt or die("Unexpected EOF from request input ($left bytes missing)") ;
		$slog->notice("HTTunnel Handler: Read $cl bytes from request input...") ;

		$left -= length($data) ;
	}

	my $l = length($data) ;
	$slog->info("HTTunnel Handler: Writing $l bytes to filehandle '$fhid'...") ;
	if ($proto eq 'udp'){
		send_to($fh, $data) ;
	}
	else {
		write_to($fh, $data) ;
	}
	$slog->notice("HTTunnel Handler: Wrote $l bytes to filehandle '$fhid'") ;

	return (undef, 0) ;
}


sub close_cmd {
	my $r = shift ;
	my @params = @_ ;

	my $slog = $r->log() ;
	my $fhid = shift @params ;

	$slog->info("HTTunnel Handler: Deleting filehandle '$fhid'...") ;
	$fdk->del($fhid) or die("Unknown filehandle '$fhid'") ;
	$slog->info("HTTunnel Handler: Filehandle '$fhid' deleted") ;

	return (undef, 0) ;
}


sub read_from {
	my $h = shift ;
	my $bufsize = shift || 0 ;

	my $buf = '' ;
	my $res = $h->sysread($buf, $bufsize) ;
	if ($res < 0){
		croak("sysread error: $!") ;
	}
	elsif ($res == 0){
		return undef ;
	}
	else {
		return $buf ;
	}
}


sub recv_from {
	my $h = shift ;
	my $bufsize = shift || 0 ;

	my $buf = '' ;
	my $res = recv($h, $buf, $bufsize, 0) ;
	if (! defined($res)){
		croak("sysread error: $!") ;
	}
	else {
		return ($res, $buf) ;
	}
}


sub write_to {
	my $h = shift ;
	my $buf = shift ;

	my $res = print $h $buf ;
	if (! $res){
		croak("print error: $!") ;
	}
}


sub send_to {
	my $h = shift ;
	my $buf = shift ;

	my $peer = getpeername($h) ;
	my $res = send($h, $buf, 0, $peer) ;

	if (! defined($res)){
		croak("send error: $!") ;
	}
}



1 ;


__DATA__


