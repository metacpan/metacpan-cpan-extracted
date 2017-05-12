package CGI::Application::Demo::Dispatch::Base;

# Author:
#	Ron Savage <ron@savage.net.au>

use base 'CGI::Application';
use strict;
use warnings;

our $VERSION = '1.05';

# -----------------------------------------------

sub cgiapp_init
{
	my($self) = @_;

	$self -> tmpl_path('/dev/shm/html/assets/templates/cgi/application/demo/dispatch');

} # End of cgiapp_init.

# -----------------------------------------------

sub path_info
{
	my($self) = @_;

	return $self -> query() -> url(-absolute => 1, -path => 1);

} # End of path_info.

# -----------------------------------------------

sub url
{
	my($self) = @_;

	return $self -> query() -> url(-absolute => 1);

} # End of url.

# -----------------------------------------------

1;
