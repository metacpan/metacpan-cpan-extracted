package App::Office::CMS::Controller::Site;

use parent 'App::Office::CMS::Controller';
use strict;
use warnings;

use JSON::XS;

use Try::Tiny;

# We don't use Moo because we isa CGI::Application.

our $VERSION = '0.93';

# -----------------------------------------------

sub add
{
	my($self) = @_;

	$self -> log(debug => 'add()');

	my($message);

	try
	{
		my($design);
		my($site);

		($message, $site, $design) = $self -> process_site_and_design_form('add');

		if (! $message)
		{
			if ($$site{exact_match} && $$design{exact_match})
			{
				$message = 'That site and design pair is already on file';
			}
			else
			{
				$message = $self -> param('db') -> site -> add($site, $design);
			}
		}
	}
	catch
	{
		$message = $_;
	};

	return $message;

} # End of add.

# -----------------------------------------------

sub cgiapp_init
{
	my($self) = @_;

	$self -> run_modes([qw/add delete duplicate update/]);

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
			$message = $self -> param('db') -> site -> delete($site);
		}
	}
	catch
	{
		$message = $_;
	};

	# search_result_div is always on screen (under the Edit Site tab).
	# It appears there by virtue of being within search.tx.
	# The other thing is, we wish to use JS to zap the displayed site
	# and the displayed search results, because that data is obsolete.

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

sub display
{
	my($self)    = @_;
	my($id_pair) = $self -> query -> param('id_pair') || '';

	$self -> log(debug => "display($id_pair)");

	# Expected format: "$site_id-$design_id".

	my($site_id, $design_id) = split(/-/, $id_pair);
	($site_id, $design_id)   = ($site_id || '0', $design_id || '0');
	my($site)   = $self -> param('db') -> site -> get_site_by_id($site_id);
	my($design) = $self -> param('db') -> design -> get_design_by_id($design_id);

	if (! ($site && $design) )
	{
		return "Error: Site with id '$site_id' and/or design with id '$design_id' not found";
	}

	# We save some data so it is available to:
	# o The update (below)
	# o Content.edit()
	# o Page.edit()
	# o Site.update()
	# We don't put it in a hidden form field, to stop tampering.

	$self -> param('session') -> param(edit_design_id => $design_id);
	$self -> param('session') -> param(edit_site_id   => $site_id);

	# update_site_div is always on screen (under the Edit Site tab).
	# It appears there by virtue of being within search.tx.

	return JSON::XS -> new -> utf8 -> encode
	({
		results =>
		{
			message    => $self -> param('view') -> site -> display($site, $design),
			target_div => 'update_site_div',
		}
	});

} # End of display.

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

		($message, $site, $design) = $self -> process_site_and_design_form('duplicate_site');

		if (! $message)
		{
			if (! $$site{new_name})
			{
				$message = $self -> param('view') -> format_errors({'Missing name' => ['You must specify a name for the new site']});
			}
			else
			{
				$message = $self -> param('db') -> site -> duplicate($site);
			}
		}
	}
	catch
	{
		$message = $_;
	};

	# search_result_div is always on screen (under the Edit Site tab).
	# It appears there by virtue of being within search.tx.
	# The other thing is, we wish to use JS to zap the displayed site
	# and the displayed search results, because that data is obsolete.

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

sub update
{
	my($self) = @_;

	$self -> log(debug => 'update()');

	my($target_div) = 'update_site_message_div';

	my($message);

	try
	{
		my($design);
		my($site);

		($message, $site, $design) = $self -> process_site_and_design_form('update');

		if (! $message)
		{
			# Success.
			# Note: If the user typed in a new site name, this will
			# call add for the site (effectively) and add for the design.
			# Note: If the user typed in a new design name, this will
			# call update for the site and add for the design.

			$message = $self -> param('db') -> site -> update($site, $design);
		}
	}
	catch
	{
		$message = $_;
	};

	# search_result_div is always on screen (under the Edit Site tab).
	# It appears there by virtue of being within search.tx.
	# update_site_message_div is only on screen (under the Edit Site tab),
	# when a site has been successfully displayed by clicking on a search result.
	# It appears there by virtue of being within site.tx.

	return JSON::XS -> new -> utf8 -> encode
	({
		results =>
		{
			message    => $message,
			target_div => $target_div,
		}
	});

} # End of update.

# -----------------------------------------------

1;
