#!/usr/bin/perl
use lib '../lib';
use CGI;
use Datastar::SSE;
use JSON;

my $q = CGI->new;
if ($q->request_method eq 'GET') {
	my $signals = +{ counter => 0 };
	print $q->header('text/html');
	$q->print(q{
	<html>
	<head>
	<script type="module" src="https://cdn.jsdelivr.net/gh/starfederation/datastar@v1.0.0-beta.11/bundles/datastar.js"></script>
	</head>
	<body data-signals='}.JSON->new->encode($signals).q{'>
	<div>Counter: <span data-text="$counter"></span></div>
	<div><button data-on-click='@post("index.cgi?action=plus")'>increment</button>
	<button data-on-click='@post("index.cgi?action=minus")'>decrement</button></div>
	</body></html>});
} else {
	print $q->header(
    	-type => 'text/event-stream',
    	-cache_control => 'no-cache',
    	-connection => 'keep-alive',
    	-keep_alive => 'timeout=300, max=100000'
	);
	my $action = $q->url_param('action');
	my $signals = JSON->new->decode(scalar $q->param('POSTDATA'));
	$signals->{counter} = $action eq 'plus' ? $signals->{counter} + 1 : $signals->{counter} - 1;
	$q->print( Datastar::SSE->merge_signals( $signals ) );
}


