package HTTunnel::Client ;
@ISA = qw(LWP::UserAgent) ;

use strict ;
use LWP::UserAgent ;
use HTTP::Request::Common ;
use HTTP::Status ;
use IO::Select ;
use Carp ;


$HTTunnel::Client::VERSION = '0.08' ;


sub new {
	my $class = shift ;
	my $url = shift ;
	my %lwp_agent_args = @_ ;

	my $this = $class->SUPER::new(
		agent => 'HTTunnel::Client/$HTTunnel::Client::VERSION', 
		keep_alive => 1,
		%lwp_agent_args
	) ;

	$url =~ s/\/+$// ;
	$this->{__PACKAGE__}->{url} = $url ;
	$this->{__PACKAGE__}->{pid} = 0 ;
	$this->{__PACKAGE__}->{peer_info} = 0 ;

	bless($this, $class) ;

	return $this ;
}


sub connect {
	my $this = shift ;
	my $proto = shift || 'tcp' ;
	my $host = shift || 'localhost' ;
	my $port = shift || 0 ;
	my $timeout = shift || 15 ;

	$this->{__PACKAGE__}->{proto} = $proto ;
	my $fhid = $this->_execute(
		'connect', 
		[$proto, $host, $port, $timeout],
	) ;
	if ($proto eq 'tcp'){
		my ($addr, $port) = () ;
		($addr, $port, $fhid) = split(':', $fhid, 3) ;
		$this->{__PACKAGE__}->{fhid} = $fhid ;
		$this->{__PACKAGE__}->{peer_info} = "$addr:$port" ;
	}
	else {
		$this->{__PACKAGE__}->{fhid} = $fhid ;
	}

	return 1 ;
}


sub read {
	my $this = shift ;
	my $len = shift || 0 ;
	my $timeout = shift || 15 ;
	my $lifeline = shift ;
	my $lifeline_action = shift || sub {die("lifeline cut\n")} ;

	croak("HTTunnel::Client object is not connected") unless $this->{__PACKAGE__}->{fhid} ;

	while (1){
		if ($lifeline){
			my @ready = IO::Select->new($lifeline)->can_read(0) ;
			if (scalar(@ready)){
				$lifeline_action->() ;
				return undef ;
			}
		}
		my $addr = undef ;
		my $port = undef ;
		my $data = undef ;
		eval {
			$data = $this->_execute(
				'read', 
				[$this->{__PACKAGE__}->{fhid}, $this->{__PACKAGE__}->{proto}, $len, $timeout],
			) ;
			if ($this->{__PACKAGE__}->{proto} eq 'udp'){
				($addr, $port, $data) = split(':', $data, 3) ;
				$this->{__PACKAGE__}->{peer_info} = "$addr:$port" ;
			}
		} ;
		if ((ref($@))&&(UNIVERSAL::isa($@, "HTTunnel::Client::TimeoutException"))){
			next ;
		}
		elsif ($@){
			die("$@\n") ;
		}

		return $data ;
	}
}


sub get_peer_info {
	my $this = shift ;

	return $this->{__PACKAGE__}->{peer_info} ;
}


sub print {
	my $this = shift ;
	my @data = shift ;

	croak("HTTunnel::Client object is not connected") unless $this->{__PACKAGE__}->{fhid} ;

	$this->_execute(
		'write',
		[$this->{__PACKAGE__}->{fhid}, $this->{__PACKAGE__}->{proto}],
		join("", @data),
	) ;

	return 1 ;
}


sub close {
	my $this = shift ;

	if ($this->{__PACKAGE__}->{fhid}){
		$this->_execute(
			'close',
			[$this->{__PACKAGE__}->{fhid}],
		) ;
		$this->{__PACKAGE__}->{fhid} = undef ;

		return 1 ;
	}
	
	return 0 ;
}


sub _execute {
	my $this = shift ;
	my $cmd = shift ;
	my $args = shift ;
	my $data = shift ;

	if ($this->{__PACKAGE__}->{pid} != $$){
		# Reset the connection cache since we probably have forked.
		if ($this->conn_cache()){
			$this->conn_cache({total_capacity => 1}) ;
		}
		$this->{__PACKAGE__}->{pid} = $$ ;
	}

	my $req = HTTP::Request::Common::POST(
		join("/", $this->{__PACKAGE__}->{url}, $cmd, @{$args}),
		{"Content-Length" => length($data || '')}, 
		"content" => $data
	) ;
	$req->protocol("HTTP/1.1") ;
	$this->request_callback($req) ;

	my $resp = $this->request($req) ;
	$this->response_callback($resp) ;
	if ($resp->code() != RC_OK()){
		croak("HTTP error : " . $resp->code() . " (" . $resp->message() . ")") ;
	}

	my $content = $resp->content() ;
	my $code = substr($content, 0, 3) ;
	if ($code eq 'err'){
		croak("Apache::HTTunnel error: " . substr($content, 3)) ;
	}
	elsif ($code eq 'okn'){
		return undef ;
	}
	elsif ($code eq 'okd'){
		return substr($content, 3) ;
	}
	elsif ($code eq 'okt'){
		die(bless({}, "HTTunnel::Client::TimeoutException")) ;
	}
	else{
		croak("Invalid Apache::HTTunnel response code '$code'") ;
	}
}


sub request_callback {
	my $shift = shift ;
	my $req = shift ;
}


sub response_callback {
	my $shift = shift ;
	my $res = shift ;
}


1 ;
