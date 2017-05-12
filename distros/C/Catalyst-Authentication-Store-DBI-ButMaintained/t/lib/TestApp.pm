package TestApp;
use strict;
use warnings;
use Catalyst;

TestApp->config($ENV{'TESTAPP_CONFIG'});
TestApp->setup(@{$ENV{'TESTAPP_PLUGINS'}});

sub login :Local
{
	my ($self, $c) = @_;
	my $req = $c->request();
	my $res = $c->response();

	eval {
		$c->authenticate({
			'name'		=> $req->param('name'),
			'password'	=> $req->param('password'),
		});
		1;
	} or do {
		return $res->body($@);
	};

	if ($c->user_exists()) {
		$res->body($c->user->get('name') . ' logged in');
	}
	else {
		$res->body('not logged in');
	}
}

sub nologin :Local
{
	my ($self, $c) = @_;
	my $req = $c->request();
	my $res = $c->response();

	eval {
		$c->authenticate({
			'name'		=> $req->param('name'),
			'password'	=> $req->param('password'),
			'active'	=> 1,
		});
		1;
	} or do {
		return $res->body($@);
	};

	if ($c->user_exists()) {
		$res->body($c->user->get('name') . ' logged in');
	}
	else {
		$res->body('user ' . $req->param('name') . ' is inactive');
	}
}

sub dologout :Local
{
	my ($self, $c) = @_;
	my $res = $c->response();

	if ($c->user()) {
		$c->logout();

		$res->body('logged out');
	}
	else {
		$res->body('not logged out');
	}
}

sub rolecheck :Local
{
	my ($self, $c) = @_;
	my $p   = $c->req->params;
	my $res = $c->res;

	if (
		$c->check_user_roles( $p->{role} )
	) {
		$res->body(
			sprintf ( "%s is in role %s", $c->user->get('name'), $p->{role} )
		);
	}
	else {
		$res->body(
			sprintf ( "%s is not in role %s", $c->user->get('name'), $p->{role} )
		);
	}

}

1;
