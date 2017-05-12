package #hide
	Test::AE::MD;

# MemcacheDB test class

use AnyEvent::Impl::Perl;
use AnyEvent;
use AnyEvent::Socket;
use AnyEvent::Memcached;
use common::sense;
use utf8;
use Test::More;
use lib::abs;

sub import {
	*{caller().'::runtest'} = \&runtest;
	@_ = 'Test::More';
	goto &{ Test::More->can('import') };
}

sub runtest(&) {
	my $cx = shift;
	my $code = sub {
		alarm 10;
		$cx->(@_,cas => 0, noreply => 0,);
	};
	my ($host,$port);
	if (defined $ENV{MEMCACHEDB_SERVER}) {
		my $testaddr = $ENV{MEMCACHEDB_SERVER};
		($host,$port) = split ':',$testaddr;$host ||= '127.0.0.1'; # allow *_SERVER=:port
		my $do;
		my $cv = AE::cv;
		$port;
		my $cg;$cg = tcp_connect $host,$port, sub {
			undef $cg;
			@_ or plan skip_all => "No memcachedb instance running at $testaddr\n";
			$cv->send; #connect
		}, sub { 1 };
		$cv->recv;
		$code->($host,$port);
	} else {
		use version;
		my $v = `memcachedb -h 2>&1`;
		$? == 0 or plan skip_all => "Can't run memcachedb: $!";
		my ($ver,$sub) = $v =~ m{.*?([\d.]+)(-\w+)?};
		qv($ver) ge qv "1.2.1" or plan skip_all => "Memcachedb too old: $ver";
		diag "using memcachedb $ver$sub";
		
		eval q{use Test::TCP;1} or plan skip_all => "No Test::TCP";
		$host = "127.0.0.1";
		my $db = lib::abs::path('tdb');
		$db .= '1' while -e $db;
		mkdir $db or plan skip_all => "Can't create test db $db: $!";
		test_tcp(
			client => sub {
				$port = shift;
				my $pid = shift;
				$code->($host,$port);
				kill TERM => $pid;
				kill KILL => $pid; # Don't like to kill it, but should.
			},
			server => sub {
				my $port = shift;
				close STDERR;
				exec("memcachedb -l $host -p $port -H $db") or
					plan skip_all => "Can't run memcachedb";
			},
		);
		unlink $_ for (<$db/*>);
		rmdir $db;
		
	}
}

1;
