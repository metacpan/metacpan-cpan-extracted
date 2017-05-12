package App::Office::CMS::Controller::Design;

use parent 'App::Office::CMS::Controller';
use common::sense;

use JSON::XS;

use Try::Tiny;

# We don't use Moose because we isa CGI::Application.

our $VERSION = '0.92';

# -----------------------------------------------

sub cgiapp_init
{
	my($self) = @_;

	$self -> run_modes([qw/delete duplicate/]);

} # End of cgiapp_init.

# -----------------------------------------------

sub delete
{
	my($self) = @_;

	$self -> log(debug => 'delete()');

	my($message);

	try
	{
		my($design);
		my($site);

		($message, $site, $design) = $self -> process_site_and_design_form('delete');

		if (! $message)
		{
			$message = $self -> param('db') -> design -> delete($site, $design);
		}
	}
	catch
	{
		$message = $_;
	};

	# search_result_div is always on screen (under the Edit Site tab).
	# It appears there by virtue of being within search.tx.

	return JSON::XS -> new -> utf8 -> encode
	({
		results =>
		{
			message    => $message,
			target_div => 'search_result_div',
		}
	});

} # End of delete.

# -----------------------------------------------

sub duplicate
{
	my($self) = @_;

	$self -> log(debug => 'duplicate()');

	my($message);

	try
	{
		my($design);
		my($site);

		($message, $site, $design) = $self -> process_site_and_design_form('duplicate_design');

		if (! $message)
		{
			# Note: The new design name is stored in the $site object.
			# See App::Office::CMS::Controller.check_site_and_design_names().

			if (! $$site{new_name})
			{
				$message = $self -> param('view') -> format_errors({'Missing name' => ['You must specify a name for the new design']});
			}
			else
			{
				$message = $self -> param('db') -> design -> duplicate($site, $design);
			}
		}
	}
	catch
	{
		$message = $_;
	};

	# search_result_div is always on screen (under the Edit Site tab).
	# It appears there by virtue of being within search.tx.

	return JSON::XS -> new -> utf8 -> encode
	({
		results =>
		{
			message    => $message,
			target_div => 'update_site_message_div',
		}
	});

} # End of duplicate.

# -----------------------------------------------

1;
