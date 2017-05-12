package TestApp;
use strict;
use warnings;
use base 'CGI::Application';
use Test::More;
use lib '../lib';
use CGI::Application::Plugin::Routes;
sub setup {
	my $self = shift;

	#as example, empty, but can be used to prepend a defined root to each route path
	$self->routes_root('');
	$self->routes([
 		'' => 'home' ,
 		'/view/:name/:id/:email'  => 'view',
	]);
	$self->start_mode('view');

#	$self->run_modes([qw/ view /]);

	$self->tmpl_path('templates/');
}
sub view {
	my $self = shift;
	my $q = $self->query();

	my $name = $q->param('name');
    is($name, 'mark', ':name has expected value');

	my $id = $q->param('id');
    is($id,76,':id has expected value');

	my $email = $q->param('email');
    is($email, 'mark@stosberg.com', ':email has expected value');

	return 'done';
}
1;
