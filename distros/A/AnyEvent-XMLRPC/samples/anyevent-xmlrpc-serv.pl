#!/usr/bin/perl
#~ use lib "lib";
use AnyEvent::XMLRPC;

my $serv = AnyEvent::XMLRPC->new(
	#~ port	=> 9090,
	#~ uri	=> "/RPC2",
	methods => {
		'echo' => \&echo,
	},
);

sub echo {
	@rep = qw(bala bababa);
	return \@rep;
}

$serv->run;