#!/usr/bin/env perl

use strict;
use lib::abs '../lib';
use AnyEvent;
use AnyEvent::Memcached;

my $cv = AnyEvent->condvar;

my @clients;
for (1..100) {
	my $memd = AnyEvent::Memcached->new(
		servers   => [ '127.0.0.1:11211' ],
		namespace => "test:",
	);
	push @clients,$memd;
}
my $t;$t = AE::timer 0,1,sub {
	# every secons one clients will delete a key
	$clients[0]->delete('key1', cb => sub {
		defined $_[0] or warn "delete failed: $_[1]";
		warn $_[0];
	});
} if 0;

# prepare a work.
# delete key and make sure all clients get connected

my $next = AE::cv;

$clients[0]->delete('key1', cb => sub {
	defined $_[0] or warn "delete failed: $_[1]";
	warn "old value was: $_[0]";
	$next->begin;
	for my $memd (@clients) {
		$next->begin;
		$memd->get('key1',cb => sub { $next->end });
	}
	$next->end;
});

$next->cb(sub {
	# now we have no this key in database, and get all clients connected
	my $reqno = 0;
	$cv->begin(sub { $cv->send });
	for my $id (1..$#clients) {
		# now, we ask every client to make repeatedly incadd, 1000 times for each;
		my $memd = $clients[$id];
		my $count = 10;
		$cv->begin;
		my $op;$op = sub {
			my $no = ++$reqno;
			$count-- == 0 and return $cv->end;
			$memd->incadd('key1',1, expire => 1, cb => sub {
				defined $_[0] or warn "@_";
				warn "$id $no -> @_";
				$op->();
			});
		};$op->();
	}
	$cv->end;
	
	# and we run deleter, that will make thing "bad"
	my $deleter;$deleter = sub {
		$clients[0]->delete('key1',cb => sub {
			warn "deleted = @_";
			my $wait;$wait = AE::timer 0,0,sub {
				undef $wait;
				$deleter->();
			};
		});
	};$deleter->();
});


$cv->recv;

__END__

$memd->set("key1", "val1", cb => sub {
	shift or warn "Set key1 failed: @_";
	warn "Set ok";
	$memd->get("key1", cb => sub {
		my ($v,$e) = @_;
		$e and return warn "Get failed: $e";
		warn "Got value for key1: $v";
	});
});

$cv->end;
$cv->recv;
