#!/usr/bin/env perl

use Test::More;
use AnyEvent::Google::PageRank qw/rank_get/;
use URI::Escape;
use IO::Socket;
use AnyEvent;
use strict;

if( $^O eq 'MSWin32' ) {
	plan skip_all => 'Fork wont work on WindoWs';
}

$AnyEvent::HTTP::MAX_PER_HOST = 10;

my $cv = AnyEvent->condvar;
$cv->begin for 1..6;

my ($pid, $host, $port) = make_rank_server(
	'http://perl.org' => [5, 5],
	'http://cpan.org' => [7, 1],
	'http://perlmonks.org' => [8, 10],
	'http://php.net' => [2, 10]
);

my $start = time();

AnyEvent::Google::PageRank->new(host => "$host:$port", timeout => 3)->get(
	'http://php.net',
	sub {
		my ($rank, $headers) = @_;
		is($rank, undef, 'php.net rank (timeout)');
		
		ok(time()-$start < 10, 'php.net non-blocking (timeout)');
		$cv->end;
	}
);

rank_get 'ftp://php.net', host => "$host:$port", sub {
	my ($rank, $headers) = @_;
	is($rank, undef, 'malformed url: ftp://php.net');
	is($headers->{Status}, 695, 'status for malformed');
	
	ok(time()-$start < 5, 'php.net non-blocking (malformed)');
	$cv->end();
};

AnyEvent::Google::PageRank->new(host => "$host:$port", ae_http => {timeout => 3})->get(
	'http://php.net',
	sub {
		my ($rank, $headers) = @_;
		is($rank, undef, 'php.net rank (ae_timeout)');
		
		ok(time()-$start < 10, 'php.net non-blocking (ae_timeout)');
		$cv->end;
	}
);

rank_get 'http://perl.org', host => "$host:$port", sub {
	my ($rank, $headers) = @_;
	is($rank, 5, 'perl.org rank');
	
	ok(time()-$start < 10, 'perl.org non-blocking');
	$cv->end;
};

rank_get 'http://perlmonks.org', host => "$host:$port", sub {
	my ($rank, $headers) = @_;
	is($rank, 8, 'perlmonks.org rank');
	
	ok(time()-$start > 5, 'perlmonks.org non-blocking');
	$cv->end;
};

AnyEvent::Google::PageRank->new(host => "$host:$port")->get(
	'http://cpan.org',
	sub {
		my ($rank, $headers) = @_;
		is($rank, 7, 'cpan.org rank');
		
		ok(time()-$start < 5, 'cpan.org non-blocking');
		$cv->end;
	}
);

$cv->recv;
kill 15, $pid;
done_testing();

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~`

sub make_rank_server {
	my %table = @_;
	my $serv = IO::Socket::INET->new(Listen => 3)
		or die $@;
		
	my $child = fork();
	die 'fork: ', $! unless defined $child;
	
	if ($child == 0) {
		while (1) {
			my $client = $serv->accept()
				or next;
			
			my $child = fork();
			die 'subfork: ', $! unless defined $child;
			
			if ($child == 0) {
				my $headers;
				while (1) {
					$client->sysread($headers, 1024, length $headers)
						or last;
					if (rindex($headers, "\015\012\015\012") != -1) {
						last;
					}
				}
			
				my ($path) = $headers =~ /GET\s+(\S+)/
					or exit;
				
				$path =~ /ch=([^&]+)/
					or exit;
				
				my ($url) = $path =~ /info:(.+)/
					or exit;
				$url = uri_unescape($url);
				
				my $response;
				if (exists $table{$url}) {
					$response = $table{$url}[0];
					sleep $table{$url}[1];
				}
				else {
					$response = 'xxx';
				}
				
				$client->syswrite(
					join(
						"\015\012",
						"HTTP/1.1 200 OK",
						"Connection: close",
						"Content-Type: text/html",
						"\015\012"
					) . "Rank_321:123:$response"
				);
				
				exit;
			}
		}
		
		exit;
	}
	
	return ($child, $serv->sockhost eq "0.0.0.0" ? "127.0.0.1" : $serv->sockhost, $serv->sockport);
}
