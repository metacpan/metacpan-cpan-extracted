package CGI::Snapp::Header;

use parent 'CGI::Snapp';
use strict;
use warnings;

our $VERSION = '2.01';

# --------------------------------------------------

sub cgiapp_get_query
{
	my($self) = @_;

	$self -> log(debug => __PACKAGE__ . '.cgiapp_get_query()');

	if (! $self -> _query)
	{
		require CGI::Simple;

		$self -> _query(CGI::Simple -> new);
	}

	return $self -> _query;

} # End of cgiapp_get_query.

# --------------------------------------------------

sub _generate_output
{
	my($self) = @_;

	$self -> log(debug => __PACKAGE__ . '._generate_output()');

	my($run_mode) = $self -> _current_run_mode;

	return 'I am module ' . __PACKAGE__ . "\n";

} # End of _generate_output.

# --------------------------------------------------

1;
