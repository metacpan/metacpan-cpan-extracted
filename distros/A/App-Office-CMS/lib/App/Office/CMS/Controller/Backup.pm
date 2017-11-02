package App::Office::CMS::Controller::Backup;

use parent 'App::Office::CMS::Controller';
use strict;
use warnings;

use JSON::XS;

use Try::Tiny;

# We don't use Moo because we isa CGI::Application.

our $VERSION = '0.93';

# -----------------------------------------------

sub build_error_result
{
	my($self, $page, $message, $target_div) = @_;

 	$self -> log(debug => "build_error_result(..., $target_div)");

	return
	{
		current_page        => $$page{name},
		homepage            => $$page{homepage},
		menu                => [],
		menu_orientation_id => 1, # TODO.
		message             => $message,
		page_name           => $$page{name},
		target_div          => $target_div,
	};

} # End of build_error_result.

# -----------------------------------------------

sub build_success_result
{
	my($self, $caller, $page, $message, $target_div) = @_;

	$self -> log(debug => "build_success_result(..., $target_div)");

	return
	{
		current_page        => $$page{name},
		homepage            => $$page{homepage},
		menu                => $self -> build_menu($caller, $page),
		menu_orientation_id => 1, # TODO: $$design{menu_orientation_id},
		message             => $message,
		page_name           => $$page{name},
		target_div          => $target_div,
	};

} # End of build_success_result.

# -----------------------------------------------

sub cgiapp_init
{
	my($self) = @_;

	$self -> run_modes([qw/run/]);

} # End of cgiapp_init.

# -----------------------------------------------

sub run
{
	my($self) = @_;

	$self -> log(debug => 'run()');

	my($target_div) = 'update_content_message_div';

	my($result);

	try
	{
		my($message, $page, $content) = $self -> process_content_form('update');

		if (! $message)
		{
			# Success.

			$message = $self -> param('db') -> content -> update($page, $content);
			$result  = $self -> build_success_result($page, $message, $target_div);
		}
	}
	catch
	{
		$result = $self -> build_error_result($_, $target_div);
	};

	# update_content_message_div is on screen (under the Edit Content tab)
	# because we're displaying content.

	return JSON::XS -> new -> utf8 -> encode({results => $result});

} # End of run.

# -----------------------------------------------

1;
