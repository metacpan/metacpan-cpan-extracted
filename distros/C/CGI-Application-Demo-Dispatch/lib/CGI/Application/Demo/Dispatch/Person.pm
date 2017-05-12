package CGI::Application::Demo::Dispatch::Person;

# Author:
#	Ron Savage <ron@savage.net.au>

use base 'CGI::Application::Demo::Dispatch::Base';
use strict;
use warnings;

our $VERSION = '1.05';

# -----------------------------------------------

sub cgiapp_init
{
	my($self) = @_;

	$self -> SUPER::cgiapp_init();
	$self -> run_modes(['display']);

} # End of cgiapp_init.

# -----------------------------------------------

sub display
{
	my($self) = @_;
	my($url)  = $self -> url();
	$url      =~ s|/Person$||;

	my(@row);

	push @row, {th => 'Package',  td => __PACKAGE__};
	push @row, {th => 'Run mode', td => $self -> get_current_runmode()};
	push @row, {th => 'URL',      td => $self -> path_info()};
 	push @row, {th => 'Go to',    td => "<a href='$url/Menu'>Menu</a>"};
 	push @row, {th => 'Go to',    td => "<a href='$url/Organization'>Organization</a>"};

	my($table) = $self -> load_tmpl('table.tmpl');

	$table -> param(tr_loop => \@row);

	my($page) = $self -> load_tmpl('web.page.tmpl');

	$page -> param(content => $table -> output() );

	return $page -> output();

} # End of display.

# -----------------------------------------------

1;
