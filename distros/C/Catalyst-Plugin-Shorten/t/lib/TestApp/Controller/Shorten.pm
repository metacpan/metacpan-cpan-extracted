package TestApp::Controller::Shorten;

use Moose;
use JSON;
use namespace::autoclean;
BEGIN { 
	extends 'Catalyst::Controller'; 
}

sub st :Chained('/') :PathPart('st') :Args('1') {
	my ($self, $c, $cap) = @_;
	$c->shorten_redirect(s => $cap);
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

sub link_url :Chained('/') :PathPart('link_url') :Args('0') {
	my ($self, $c) = @_;
	my $uri = $c->uri_for('/extract', { okay => 1, not => 2, random => 3 });
	$uri = $c->shorten(as_uri => 1, uri => $uri);
	$c->res->body($uri->as_string);
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

sub delete :Chained('/') :PathPart('delete') :Args('0') {
	my ($self, $c) = @_;
	
	$c->shorten_delete();
	$c->res->body(sprintf 'deleted %s', $c->req->param('s'));
}

sub ddelete :Chained('/') :PathPart('ddelete') :Args('1') {
	my ($self, $c, $cap) = @_;
	$c->shorten_delete(s => $cap);
	$c->res->body(sprintf 'deleted %s', $cap);
}

sub cb_shorten :Chained('/') :PathPart('cb_shorten') :Args('0') {
	my ($self, $c) = @_;
	my $str = $c->shorten(store => { user => 'me' });
	$c->res->body($str);
}

sub cb_redirect :Chained('/') :PathPart('cb_redirect') :Args('1') {
	my ($self, $c, $cap) = @_;
	$c->shorten_redirect(params => $c->req->params, s => $cap, cb => \&cb);
}

sub cb_params :Chained('/') :PathPart('cb_params') :Args('0') {
	my ($self, $c) = @_;
	my $params = $c->shorten_params(params => $c->req->params, cb => \&cb);
	if ($params) { 
		$c->res->content_type('application/json');
		$c->res->body(JSON->new->encode($params));
	} else {
		$c->res->body('');
	}
}

sub cb_extract :Chained('/') :PathPart('cb_extract') :Args('0') {
	my ($self, $c) = @_;
	# cba to mock a user object so use a param ;).
	$c->shorten_extract(params => $c->req->params, cb => \&cb);
	$c->res->content_type('application/json');
	$c->res->body(JSON->new->encode($c->req->params));
}

sub cb {
	my ($c, $row) = @_;

	# $c->user();
	my $params = $c->req->params;
	if ($params->{user} eq $row->{user}) {
		return $row;
	}
	return;
}

1;
