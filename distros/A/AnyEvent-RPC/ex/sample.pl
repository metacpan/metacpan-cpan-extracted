#!/usr/bin/env perl

use AnyEvent::Impl::Perl;

use lib::abs '../lib';

package AE::RPC::Enc::Sample;

use uni::perl;
use parent 'AnyEvent::RPC::Enc::REST';

sub request {
	my $self = shift;
	my $rpc = shift;
	my %args = @_;
	$args{query}{api_key} //= '123';
	$self->next::method($rpc,%args);
}

package main;

use uni::perl ':dumper';
use AnyEvent;
use AnyEvent::RPC;

my $rpc = AnyEvent::RPC->new(
	host      => 'rpc.provider.com',
	base      => '/api/rest/',
	encoder   => '+AE::RPC::Enc::Sample',
	timeout   => 0.5,
	debug     => 10,
);

my $cv = AE::cv;

$cv->begin;
# Will call GET http://rpc.provider.com/api/rest/some/param/line?api_key=123
$rpc->req(
	method => 'GET',
	call   => [ user => qw(some param line) ],
	cb => sub {
		warn dumper \@_;
		$cv->end;
	},
);

$cv->begin;
# Will call POST http://rpc.provider.com/api/rest/some/param/line?api_key=123&add=arg
# And postdata =
#   <?xml version="1.0" encoding="utf-8"?><r><test>ok</test></r>
$rpc->req(
	method => 'POST',
	call   => [ user => qw(some param line) ],
	query  => { add => 'arg' },
	data   => { r => {test => "ok"} },
	cb => sub {
		warn dumper \@_;
		$cv->end;
	},
);

$cv->recv;
