package #hide
	Test::AE::MC;

# Memcached test class

use Test::More;
use AnyEvent::Impl::Perl;
use AnyEvent;
use AnyEvent::Socket;
BEGIN{ eval q{use AnyEvent::Memcached;1} or BAIL_OUT("$@") }
use common::sense;
use utf8;

sub import {
	*{caller().'::runtest'} = \&runtest;
	@_ = 'Test::More';
	goto &{ Test::More->can('import') };
}

sub runtest(&) {
	my $cx = shift;
	my $code = sub {
		alarm 10;
		eval {
			$cx->(@_,noreply => 1, cas => 1);
			1;
		} or do {
			warn "DIED $@";
			die "$@";
		}
		
	};
	my ($host,$port);
	if (defined $ENV{MEMCACHED_SERVER}) {
		my $testaddr = $ENV{MEMCACHED_SERVER};
		($host,$port) = split ':',$testaddr;$host ||= '127.0.0.1'; # allow *_SERVER=:port
		my $do;
		my $cv = AE::cv;
		$port;
		my $cg;$cg = tcp_connect $host,$port, sub {
			undef $cg;
			@_ or plan skip_all => "No memcached instance running at $testaddr\n";
			$cv->send; #connect
		}, sub { 1 };
		$cv->recv;
		$code->($host,$port);
	} else {
		use version;
		my $v = `memcached -h 2>&1`;
		$? == 0 or plan skip_all => "Can't run memcached: $!";
		my ($ver,$sub) = $v =~ m{.*?([\d.]+)(-\w+)?};
		qv($ver) ge qv "1.2.4" or plan skip_all => "Memcached too old: $ver";
		diag "using memcached $ver$sub";
		
		eval q{use Test::TCP;1 } or plan skip_all => "No Test::TCP";
		$host = "127.0.0.1";
		test_tcp(
			client => sub {
				$port = shift;
				$code->($host,$port);
			},
			server => sub {
				my $port = shift;
				exec("memcached -l $host -p $port") or plan skip_all => "Can't run memcached";
			},
		)
	}
}

1;
