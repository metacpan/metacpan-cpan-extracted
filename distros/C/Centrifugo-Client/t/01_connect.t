use strict;
use warnings;
use 5.010;

my $CENTRIFUGO_DEMO = 'centrifugo.herokuapp.com';
my $DEBUG = 0;

use Test::More tests => 1;

use Centrifugo::Client;

SKIP: {
	eval 'use Digest::SHA qw( hmac_sha256_hex )';
	skip "Digest::SHA not available", 1 if $@;
	
	our $condvar = AnyEvent->condvar;

	# This part is aiming to get a valid TOKEN for Centrifugo_demo site.
	# On real application, this step should ALWAYS be done on server side
	my $USER      = 'perl-module-test';
	my $TIMESTAMP = time();
	my $SECRET = "secret";
	
	my $TOKEN = hmac_sha256_hex( $USER, $TIMESTAMP, $SECRET );
	
	my $SUCCESS = 0;
	
	my $cclient = Centrifugo::Client->new("ws://$CENTRIFUGO_DEMO/connection/websocket", debug => $DEBUG );

	$cclient-> on('connect', sub{
		my ($infoRef)=@_;
		$SUCCESS = 'true';
		$condvar->send;
	})-> on('disconnect', sub{
		my ($infoRef)=@_;
		diag "Received : Disconnected : ".$infoRef;
		$condvar->send;
	})-> on('error', sub{
		my ($error)=@_;
		$condvar->send;
	})-> on('ws_closed', sub{
		diag "Received : Websocket connection closed";
		$condvar->send;
	})->connect(
		user => $USER,
		timestamp => $TIMESTAMP,
		token => $TOKEN
	);
	
	$condvar->recv;
	
	ok( $SUCCESS, "Successfully connected to ws://$CENTRIFUGO_DEMO");
}
	