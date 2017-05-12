#!/usr/bin/env perl

BEGIN {
	print "1..0 # SKIP: Currrently broken\n";
	exit 0;
}
use common::sense;
use lib::abs '../lib';
use Devel::Rewrite;
BEGIN {$ENV{DEBUG_CB} = 1}
package Echo::Client;

use base 'AnyEvent::Connection';

package main;

use Test::TCP;
use AnyEvent::Impl::Perl;
use AnyEvent;
use AnyEvent::Socket;

use Test::More tests => 22;
use Test::NoWarnings;

diag "Testing AnyEvent::Connection $AnyEvent::Connection::VERSION $INC{'AnyEvent/Connection.pm'}";

my $cv = AnyEvent->condvar;
$SIG{ALRM} = sub { $cv->send; die "Alarm clock"; };
alarm 10;
test_tcp(
	server => sub {
		my $port = shift;
		diag "$$: sr $port";
		my $count;
		my %st;
		$st{server} = tcp_server undef,$port, sub {
			#warn "got conn @_";
			my $h = AnyEvent::Handle->new(
				fh => $_[0],
			);
			$h->on_error(sub{ $h->destroy; undef $h; });
			$h->push_read(line => sub {
				shift;
				if ($_[0] =~ /reset/) {
					diag "Initiating connection reset";
					#$h->push_write("some shit \n");
					$h->destroy;
					undef $h;
					%st = ();
					$st{server} = tcp_server undef,$port, sub {
						#warn "got new conn @_";
					};
				}
			});
		};
		$cv->recv;
	},
	client => sub {
		my $port = shift;
		diag "$$: cl $port";
		my $cl = Echo::Client->new(
			host  => '127.0.0.1',
			port  => $port,
			reconnect => 0.1,
			debug => 0,
		);
		my $action = 0;
		$cl->reg_cb(
			connected => sub {
				isa_ok $_[0], 'AnyEvent::Connection', 'connected client';
				isa_ok $_[1], 'AnyEvent::Connection::Raw', 'connected connection';
				is $_[2], '127.0.0.1', 'connected host';
				is $_[3], $port, 'connected port';
				if($action == 0) {
					shift->reconnect();
				}
				elsif ($action == 1) {
					shift->disconnect('requested');
				}
				elsif ($action == 2) {
					# Wait for reset
					$_[1]->command("reset", cb => sub {
						ok !shift, 'callback failed';
						like shift, qr/destroying/, 'error is destroy';
					});
				}
				else {
					#warn "connected action = $action";
					shift->disconnect('finish');
				}
			},
			connfail => sub {
				fail "@_";
			},
			disconnect => sub {
				shift;
				$action++;
				if ($action == 1) {
					ok !@_, 'disconnect by reconnect';
					$cl->connect;
				}
				elsif ($action == 2) {
					is $_[0], 'requested', 'requested disconnect';
					$cl->connect;
				}
				elsif ($action == 3) {
					# Do nothing, wait for auto reconnect
				}
				else {
					is $_[0], 'finish', 'finish disconnect';
					$cv->send;
				}
			},
		);
		$cl->connect;
		$cv->recv;
		undef $cl; # test destruction
	},
);
