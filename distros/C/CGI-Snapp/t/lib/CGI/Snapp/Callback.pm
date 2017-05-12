package CGI::Snapp::Callback;

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

sub cgiapp_init
{
	my($self) = @_;

	$self -> log(debug => __PACKAGE__ . '.cgiapp_init()');

} # End of cgiapp_init.

# --------------------------------------------------

sub cgiapp_prerun
{
	my($self) = @_;

	$self -> log(debug => __PACKAGE__ . '.cgiapp_prerun()');

} # End of cgiapp_prerun.

# --------------------------------------------------

sub cgiapp_postrun
{
	my($self) = @_;

	$self -> log(debug => __PACKAGE__ . '.cgiapp_postrun()');

} # End of cgiapp_postrun.

# --------------------------------------------------

sub _generate_output
{
	my($self) = @_;

	$self -> log(debug => __PACKAGE__ . '._generate_output()');

	my($run_mode) = $self -> _current_run_mode;

	return 'I am module ' . __PACKAGE__ . "\n";

} # End of _generate_output.

# --------------------------------------------------

sub setup
{
	my($self) = @_;

	$self -> log(debug => __PACKAGE__ . '.setup()');

	# Add callback methods belonging to this package.

	__PACKAGE__ -> add_callback('prerun', 'cgiapp_prerun');
	__PACKAGE__ -> add_callback('postrun', 'cgiapp_postrun');
	$self -> add_callback('teardown', 'teardown');

} # End of setup.

# --------------------------------------------------

sub teardown
{
	my($self) = @_;

	$self -> log(debug => __PACKAGE__ . '.teardown()');

} # End of teardown.

# --------------------------------------------------

1;
