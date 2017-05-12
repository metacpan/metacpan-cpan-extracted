#!/usr/bin/perl

use strict;
use warnings;

use IO::Socket;
use Calculator;
use srv_calc;

my $sock = IO::Socket::INET->new(
		LocalPort	=> 12345,
		Proto		=> 'tcp',
		Type		=> SOCK_STREAM,
		Reuse		=> 1,
		Listen		=> 10,
) or die "can't open socket ($@)";

my $servant = new CORBA::Perl::GIOP::Servant();
my $my_impl_calc = new MyImplCalc();
$servant->Register(Calculator::Calculator__id(), $my_impl_calc);

print "waiting first data ...\n";
while (my $client = $sock->accept()) {
	my $reply = undef;
	while (! defined $reply) {
		my $request;
		$client->recv($request, 1024);
		print "data (", length $request, ") received.\n";
		$reply = $servant->ServantNB($request);
	}
	$client->send($reply) if ($reply);
	$client->close();
}



