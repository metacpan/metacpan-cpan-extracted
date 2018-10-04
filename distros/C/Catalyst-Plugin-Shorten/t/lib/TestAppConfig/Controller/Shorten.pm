package TestAppConfig::Controller::Shorten;

use Moose;
use JSON;
use namespace::autoclean;
BEGIN { 
	extends 'Catalyst::Controller'; 
}

sub st :Chained('/') :PathPart('st') :Args('1') {
	my ($self, $c, $cap) = @_;
	$c->shorten_redirect(g => $cap);
}

sub shorten :Chained('/') :PathPart('shorten') :Args('0') {
	my ($self, $c) = @_;
	
	my $params = $c->req->params;
	if ($params->{longer}) {
		$c->shorten_offset_set(900000000);
	}

	my $shorten = $c->shorten(as_uri => 1);
	my $html = sprintf q|<html>
	<head>
		<style>
			body {
				background: #000;
				color: #fff;
			}
		</style>
	</head>
	<body>
		<h2>Test extracting params from short url forward/detach</h2>
		<h3>Shortened URL: %s</h3>
		<div>
			%s
		</div>
	</body
</html>|, $shorten, join("\n\t\t\t", map { sprintf q|<p><b>%s</b>%s</p>|, $_, $params->{$_} } sort keys %{$params});

	$c->res->body($html);
}

sub params :Chained('/') :PathPart('params') :Args('0') {
	my ($self, $c) = @_;
	my $params = $c->shorten_params();
	$c->res->content_type('application/json');
	$c->res->body(JSON->new->encode($params));
}

sub extract :Chained('/') :PathPart('extract') :Args('0') {
	my ($self, $c) = @_;
	my $params = $c->req->params();
	if ($params->{no_merge}) {
		$c->shorten_extract(no_merge => 1);
	} else {
		$c->shorten_extract();
	}
	$c->res->content_type('application/json');
	$c->res->body(JSON->new->encode($c->req->params));
}

1;
