package App::Office::CMS::Controller::Search;

use parent 'App::Office::CMS::Controller';
use strict;
use warnings;

# We don't use Moo because we isa CGI::Application.

our $VERSION = '0.93';

# -----------------------------------------------

sub display
{
	my($self) = @_;

	$self -> log(debug => 'display()');

	my($name)   = $self -> query -> param('name') || '';
	my($result) = $self -> param('db') -> site -> search($name);
	$result     = $self -> param('db') -> design -> search($name, $result);
	$result     = $self -> param('db') -> page -> search($name, $result);

	return $self -> param('view') -> search -> display($name, $result);

} # End of display.

# -----------------------------------------------

1;
