#!/usr/bin/env perl

use Test::More;
use strict;
use IO::Socket::Socks qw/:constants $SOCKS_ERROR/;
BEGIN { 
	if( $^O eq 'MSWin32' ) {
		plan skip_all => 'Fork + Windows = Fail';
	}
	
	$ENV{http_proxy} = $ENV{HTTP_PROXY} = 
	$ENV{https_proxy} = $ENV{HTTPS_PROXY} = 
	$ENV{all_proxy} = $ENV{ALL_PROXY} = undef;
	
	use_ok('AnyEvent::HTTP::Socks');
};

$AnyEvent::HTTP::MAX_PER_HOST = 10;

my ($h_pid, $h_host, $h_port) = make_http_server();
my ($s1_pid, $s1_host, $s1_port) = make_socks_server(4, undef, undef, accept => 1, reply => 2);
my ($s2_pid, $s2_host, $s2_port) = make_socks_server(5, 'root', 'toor', accept => 2, reply => 3);
my ($s3_pid, $s3_host, $s3_port) = make_socks_server(5, undef, undef, reply => 1);
my ($s4_pid, $s4_host, $s4_port) = make_socks_server(4, undef, undef, accept => 5);

my $loop = AnyEvent->condvar;
$loop->begin;
my $start = time();

$loop->begin;
http_get "http://$h_host:$h_port/", socks => "socks4://$s1_host:$s1_port", sub {
	ok(time()-$start<5, "Socks4 with delay=3");
	is($_[0], 'ROOT', 'response over Socks4');
	$loop->end;
};

$loop->begin;
http_get "http://$h_host:$h_port/index", socks => "socks5://root:toor\@$s2_host:$s2_port", sub {
	ok(time()-$start>3, "Socks5 with auth delay=5");
	is($_[0], 'INDEX', 'response over Socks5 with auth');
	$loop->end;
};

$loop->begin;
http_get "http://$h_host:$h_port/unknown", socks => "socks5://$s3_host:$s3_port", sub {
	ok(time()-$start<3, "Socks5 delay=1");
	is($_[0], 'UNKNOWN', 'response over Socks5');
	$loop->end;
};

$loop->begin;
http_get "http://$h_host:$h_port/", timeout => 3, socks => "socks4://$s4_host:$s4_port", sub {
	is($_[1]->{Status}, 595, 'Timeout');
	$loop->end;
};

$loop->begin;
http_get "http://$h_host:$h_port/", socks => "socks5://$s3_host:$s3_port -> socks4://$s1_host:$s1_port", sub {
	is($_[0], 'ROOT', 'socks5 -> socks4 chain');
	$loop->end;
};

$loop->begin;
http_get "http://$h_host:$h_port/index", socks => "socks5://$s3_host:$s3_port	socks5://xxx:xxx\@$s2_host:$s2_port", sub {
	is($_[0], undef, 'socks5 -> socks5[auth] chain with bad password');
	$loop->end;
};

$loop->begin;
http_get "http://$h_host:$h_port/index", socks => "socks5://$s3_host:$s3_port  socks5://root:toor\@$s2_host:$s2_port", sub {
	is($_[0], 'INDEX', 'socks5 -> socks5[auth] chain with good password');
	$loop->end;
};

$loop->end;
$loop->recv;

kill 15, $_ for ($h_pid, $s1_pid, $s2_pid, $s3_pid, $s4_pid);

done_testing();

sub make_socks_server {
	my ($version, $login, $password, %delay) = @_;
	
	my $serv = IO::Socket::Socks->new(Listen => 3, SocksVersion => $version, RequireAuth => ($login && $password), UserAuth => sub {
		return $_[0] eq $login && $_[1] eq $password;
	}) or die $@;
	
	my $child = fork();
	die 'fork: ', $! unless defined $child;
	
	if ($child == 0) {
		while (1) {
			if ($delay{accept}) {
				sleep $delay{accept};
			}
			my $client = $serv->accept()
				or next;
			
			my $subchild = fork();
			die 'subfork: ', $! unless defined $subchild;
			
			if ($subchild == 0) {
				my ($cmd, $host, $port) = @{$client->command()};
				
				if($cmd == CMD_CONNECT)
				{ # connect
					my $socket = "$IO::Socket::Socks::SOCKET_CLASS"->new(PeerHost => $host, PeerPort => $port, Timeout => 10);
					if ($delay{reply}) {
						sleep $delay{reply};
					}
					if($socket)
					{
						# request granted
						$client->command_reply($version == 4 ? REQUEST_GRANTED : REPLY_SUCCESS, $socket->sockhost, $socket->sockport);
					}
					else
					{
						# request rejected or failed
						$client->command_reply($version == 4 ? REQUEST_FAILED : REPLY_HOST_UNREACHABLE, $host, $port);
						$client->close();
						exit;
					}
					
					my $selector = IO::Select->new($socket, $client);
					
					MAIN_CONNECT:
					while(1)
					{
						my @ready = $selector->can_read();
						foreach my $s (@ready)
						{
							my $readed = $s->sysread(my $data, 1024);
							unless($readed)
							{
								# error or socket closed
								$socket->close();
								last MAIN_CONNECT;
							}
							
							if($s == $socket)
							{
								# return to client data readed from remote host
								$client->syswrite($data);
							}
							else
							{
								# return to remote host data readed from the client
								$socket->syswrite($data);
							}
						}
					}
				}
				
				exit;
			}
		}
	}
	
	return ($child, fix_addr($serv->sockhost), $serv->sockport);
}

sub make_http_server {
	my $serv = IO::Socket::INET->new(Listen => 3)
		or die $@;
	
	my $child = fork();
	die 'fork: ', $! unless defined $child;
	
	if ($child == 0) {
		while (1) {
			my $client = $serv->accept()
				or next;
			
			my $subchild = fork();
			die 'subfork: ', $! unless defined $subchild;
			
			if ($subchild == 0) {
				my $buf;
				while (1) {
					$client->sysread($buf, 1024, length $buf)
						or last;
					if (rindex($buf, "\015\012\015\012") != -1) {
						last;
					}
				}
				
				my ($path) = $buf =~ /GET\s+(\S+)/
					or exit;
				
				my $response;
				if ($path eq '/') {
					$response = 'ROOT';
				}
				elsif ($path eq '/index') {
					$response = 'INDEX';
				}
				else {
					$response = 'UNKNOWN';
				}
				
				$client->syswrite(
					join(
						"\015\012",
						"HTTP/1.1 200 OK",
						"Connection: close",
						"Content-Type: text/html",
						"\015\012"
					) . $response
				);
				
				exit;
			}
		}
		
		exit;
	}
	
	return ($child, fix_addr($serv->sockhost), $serv->sockport);
}

sub fix_addr {
	return '127.0.0.1' if $_[0] eq '0.0.0.0';
	return '[0:0:0:0:0:0:0:1]' if $_[0] eq '::';
	return "[$_[0]]" if index($_[0], ':') != -1;
	return $_[0];
}
