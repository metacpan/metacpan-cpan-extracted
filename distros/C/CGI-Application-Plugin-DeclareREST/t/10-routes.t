use strict;
use warnings;

package TestApp;

use base 'CGI::Application';
use CGI::Application::Plugin::DeclareREST;

get 'route66' => sub {
	my $self = shift;
	return 'go ahead';
};

post 'route66' => sub {
	my $self = shift;
	my $q    = $self->query;
	
	return 'posted param distance = ' . $q->param('distance');
};

del 'route66' => sub {
	return 'route deleted!';
};

get 'foo/:id' => sub {
	my $self = shift;
	my $id   = $self->captures->{id};
	return "foo $id bar";
};

# 2 captures
get 'foo/:id/:section' => sub {
	my $self = shift;
	my $id   = $self->captures->{id};
	my $sect = $self->captures->{section};
	return "id: $id section: $sect";
};

any [qw( post del )] => 'anything/:goes' => sub {
	my $self = shift;
	my $goes = $self->captures->{goes};
	#my $self->http_method
	
	return "$goes goes";
};

get 'number/:int', constraints => {'int' => qr/\d+/} => sub {
		return 'number is ' . (shift)->captures->{'int'};
	};

get '*any' => sub {
	return 'catch all: ' . (shift)->captures->{'any'};
};

get 'never' => sub {
	return 'you never get this';
};

package main;

use Test::More;
use Test::WWW::Mechanize::PSGI;

use Plack::Builder;
use CGI::PSGI;
use CGI::Application::PSGI;

my $test_app = sub {
	my $app = TestApp->new({ QUERY => CGI::PSGI->new(shift) });
	CGI::Application::PSGI->run( $app );
};

my $mech = Test::WWW::Mechanize::PSGI->new(
	app => builder {
		mount '/' => $test_app,
	}
);

$mech->get_ok('/route66');
$mech->content_is('go ahead');

$mech->post_ok('/route66', { distance => 42 });
$mech->content_is('posted param distance = 42');

$mech->delete('/route66');
$mech->content_is('route deleted!');

$mech->get_ok('/foo/123');
$mech->content_is('foo 123 bar');

$mech->get_ok('/foo/123/footer');
$mech->content_is('id: 123 section: footer');

$mech->post_ok('anything/something');
$mech->content_is('something goes');

$mech->get_ok('/number/123');
$mech->content_is('number is 123');

$mech->get_ok('/number/asdf');
ok( $mech->content !~ /number is asdf/);

$mech->get_ok('/asdffgdsfdasfdsa');
$mech->content_is('catch all: asdffgdsfdasfdsa/');

$mech->get_ok('/never');
$mech->content_is('catch all: never/');

done_testing();
