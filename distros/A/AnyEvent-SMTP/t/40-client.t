#!/usr/bin/env perl


use strict;
use warnings;
use AnyEvent::Impl::Perl;
use AnyEvent;
use AnyEvent::Socket;

use lib::abs '../lib';

use Test::More;
use AnyEvent::SMTP qw(smtp_server sendmail);

our $port = 1024 + $$ % (65535-1024) ;
our $ready = 0;
$SIG{INT} = $SIG{TERM} = sub { exit 0 };

our $child;
unless($child = fork) {
	# Start server and wait for connections
	my $cv = AnyEvent->condvar;
	my $req = 2;
	smtp_server undef, $port, sub { };
	$cv->recv;
} else {
	# Wait for server to start
	my $cv = AnyEvent->condvar;
	my ($conn,$cg);
	$cv->begin(sub {
		undef $conn;
		undef $cg;
		$cv->send;
	});
	$conn = sub {
		$cg = tcp_connect '127.0.0.1',$port, sub {
			return $cv->end if @_;
			$!{ENODATA} or $!{ECONNREFUSED} or plan skip_all => "Bad response from server connect: [".(0+$!)."] $!"; 
			my $t;$t = AnyEvent->timer( after => 0.05, cb => sub { undef $t; $conn->() } );
		};
	};
	$conn->();
	$cv->recv;
}

plan tests => 3;

my $cv = AnyEvent->condvar;
$cv->begin(sub { $cv->send; });

sendmail
	# debug  => 1,
	host   => '127.0.0.1', port => $port,
	from   => 'test@test.test',
	to     => 'tset@tset.tset',
	data   => 'body',
	cv     => $cv,
	cb     => sub {
		like $_[0], qr/^250 /, 'Response 250'
			or diag "  Error: $_[1]";
		
	};

sendmail
	# debug  => 1,
	timeout => 1,
	host   => '127.0.0.1', port => 1,
	from   => 'test@test.test',
	to     => 'tset@tset.tset',
	data   => 'body',
	cv     => $cv,
	cb     => sub {
		ok $_[1], 'Error on bad port: '.$_[1];
		diag "OK = $_[0]" if $_[0];
		
	};

SKIP: {
	$ENV{NET_TEST} or skip '$ENV{NET_TEST} not enabled',1;
sendmail
	# debug  => 1,
	timeout => 1,
	host   => '1.1.1.1', port => 1,
	from   => 'test@test.test',
	to     => 'tset@tset.tset',
	data   => 'body',
	cv     => $cv,
	cb     => sub {
		ok $_[1], 'Error on bad host: '.$_[1];
		diag "OK = $_[0]" if $_[0];
	};

}


$cv->end;
$cv->recv;

END {
	if ($child) {
		#warn "Killing child $child";
		$child and kill TERM => $child or warn "$!";
		waitpid($child,0);
		exit 0;
	}
}
