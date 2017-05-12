package TestApp::Controller::Root;

use strict;
use warnings;

use base 'Catalyst::Controller';

__PACKAGE__->config(namespace => '');

sub auto : Private
{
	my $self	= shift;
	my $c		= shift;

	$c->authenticate;

	return 1;
}

sub defaut : Path
{
	my $self	= shift;
	my $c		= shift;

	my @a;

	push @a, $c->user ? 1 : 0;									# has_user
	push @a, $c->user ? $c->user->id : '';						# user id
	push @a, $c->user ? join ';', sort $c->user->roles : '';	# user roles

	$c->res->body(join "\n", @a);
}

sub admin : Local
{
	my $self	= shift;
	my $c		= shift;

	$c->assert_user_roles('admin');

	$c->res->body('OK');
}

sub protected : Local
{
	my $self	= shift;
	my $c		= shift;

	$c->assert_user_roles('user', 'tester');

	$c->res->body('OK');
}

sub headers : Local
{
	my $self	= shift;
	my $c		= shift;

	$c->res->body($c->req->headers->as_string);
}

1;
