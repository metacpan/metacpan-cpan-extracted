package App::Office::CMS::Controller::Page;

use parent 'App::Office::CMS::Controller';
use common::sense;

use Data::Dumper::Concise;

use JSON::XS;

use Try::Tiny;

# We don't use Moose because we isa CGI::Application.

our $VERSION = '0.92';

# -----------------------------------------------

sub add_child
{
	my($self) = @_;

	$self -> log(debug => 'add_child()');

	# These keys are used in the return statement,
	# but should only be displayed in case of error.

	my($page) =
	{
		curent_page => 'N/A',
		homepage    => 'No',
		page_name   => 'N/A',
	};
	my($target_div) = 'update_page_message_div';

	my($result);

	try
	{
		my($asset);
		my($message);

		($message, $page, $asset) = $self -> process_page_form('add');

		if ($message)
		{
			$result = $self -> build_error_result($page, $message, $target_div);
		}
		else
		{
			# Success.

			$message = $self -> param('db') -> page -> add_child($page, $asset);
			$result  = $self -> build_success_result('add_child', $page, $message, $target_div);
		}
	}
	catch
	{
		$result = $self -> build_error_result($page, $_, $target_div);
	};

	# update_page_message_div is on screen (under the Edit Pages tab),
	# because we're displaying a page using page.tx.

	return JSON::XS -> new -> utf8 -> encode({results => $result});

} # End of add_child.

# -----------------------------------------------

sub add_sibling_above
{
	my($self) = @_;

	$self -> log(debug => 'add_sibling_above()');

	# These keys are used in the return statement,
	# but should only be displayed in case of error.

	my($page) =
	{
		curent_page => 'N/A',
		homepage    => 'No',
		page_name   => 'N/A',
	};
	my($target_div) = 'update_page_message_div';

	my($result);

	try
	{
		my($asset);
		my($message);

		($message, $page, $asset) = $self -> process_page_form('add');

		if ($message)
		{
			$result = $self -> build_error_result($page, $message, $target_div);
		}
		else
		{
			# Success.

			$message = $self -> param('db') -> page -> add_sibling_above($page, $asset);
			$result  = $self -> build_success_result('add_sibling_above', $page, $message, $target_div);
		}
	}
	catch
	{
		$result = $self -> build_error_result($page, $_, $target_div);
	};

	# update_page_message_div is on screen (under the Edit Pages tab),
	# because we're displaying a page using page.tx.

	return JSON::XS -> new -> utf8 -> encode({results => $result});

} # End of add_sibling_above.

# -----------------------------------------------

sub add_sibling_below
{
	my($self) = @_;

	$self -> log(debug => 'add_sibling_below()');

	# These keys are used in the return statement,
	# but should only be displayed in case of error.

	my($page) =
	{
		curent_page => 'N/A',
		homepage    => 'No',
		page_name   => 'N/A',
	};
	my($target_div) = 'update_page_message_div';

	my($result);

	try
	{
		my($asset);
		my($message);

		($message, $page, $asset) = $self -> process_page_form('add');

		if ($message)
		{
			$result = $self -> build_error_result($page, $message, $target_div);
		}
		else
		{
			# Success.

			$message = $self -> param('db') -> page -> add_sibling_below($page, $asset);
			$result  = $self -> build_success_result('add_sibling_below', $page, $message, $target_div);
		}
	}
	catch
	{
		$result = $self -> build_error_result($page, $_, $target_div);
	};

	# update_page_message_div is on screen (under the Edit Pages tab),
	# because we're displaying a page using page.tx.

	return JSON::XS -> new -> utf8 -> encode({results => $result});

} # End of add_sibling_below.

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

sub build_menu
{
	my($self, $caller, $page) = @_;

	$self -> log(debug => "build_menu($caller, $$page{name})");

	# The reason for checking for a click is that when a user clicks on an item,
	# we want the Ajax to update the screen, but we don't want to recreate
	# the menu, because the item might have a submenu, and recreating it would
	# mean the submenu would not be open to allow selection of submenu items.

	my($menu) = [];

	if ($caller =~ /click_on_tree/)
	{
	}
	else
	{
		my($tree) = $self -> param('db')-> menu -> get_menu_by_context($$page{context});

		# We use $tree -> daughters to exclude the dummy root node.

		$menu = $self -> build_structure($tree -> daughters);
	}

	return $menu;

} # End of build_menu.

# -----------------------------------------------
# Note: Since this method is recursive, we don't log each entry.

sub build_structure
{
	my($self, @node) = @_;
	my($item_data)   = [];

	my(@daughters);

	for my $node (@node)
	{
		@daughters = $node -> daughters;

		if ($#daughters >= 0)
		{
			push @$item_data,
			{
				children => $self -> build_structure(@daughters),
				expanded => JSON::XS::true,
				label    => $node -> name,
				type     => 'text',
			};
		}
		else
		{
			push @$item_data,
			{
				label => $node -> name,
				type  => 'text',
			};
		}
	}

	return $item_data;

} # End of build_structure.

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

	$self -> run_modes([qw/add_sibling_above add_sibling_below add_child click_on_tree delete update/]);

} # End of cgiapp_init.

# -----------------------------------------------

sub click_on_tree
{
	my($self) = @_;

 	$self -> log(debug => 'click_on_tree()');

	# These keys are used in the return statement,
	# but should only be displayed in case of error.

	my($page) =
	{
		curent_page => 'N/A',
		homepage    => 'No',
		page_name   => 'N/A',
	};
	my($target_div) = 'update_page_message_div';

	my($result);

	try
	{
		my($asset);
		my($message);

		# We use 'click' for the action so as to get an error if anything untoward happens.

		($message, $page, $asset) = $self -> process_page_form('click');

		if ($message)
		{
			$result = $self -> build_error_result($page, $message, $target_div);
		}
		else
		{
			# Success.
			# We have to update the session to match the menu item clicked on.

			$self -> param('session') -> param(edit_page_id => $$page{id});

			$result = $self -> build_success_result('click_on_tree', $page, 'Changed current page', $target_div);
		}
	}
	catch
	{
		$result = $self -> build_error_result($page, $_, $target_div);
	};

	# update_page_message_div is on screen (under the Edit Pages tab),
	# because we're displaying a page using page.tx.

	return JSON::XS -> new -> utf8 -> encode({results => $result});

} # End of click_on_tree.

# -----------------------------------------------

sub delete
{
	my($self) = @_;

	$self -> log(debug => 'delete()');

	# These keys are used in the return statement,
	# but should only be displayed in case of error.

	my($page) =
	{
		curent_page => 'N/A',
		homepage    => 'No',
		page_name   => 'N/A',
	};
	my($target_div) = 'update_page_message_div';

	my($result);

	try
	{
		my($asset);
		my($message);

		($message, $page, $asset) = $self -> process_page_form('delete');

		if ($message)
		{
			$result = $self -> build_error_result($page, $message, $target_div);
		}
		else
		{
			# Success.
			# After deleting the 'current' page, delete() will have reset
			# edit_page_id within the session object, so make that page current.
			# Warning: This ignores the fact that $asset no longer matches $page.

			$message = $self -> param('db') -> page -> delete($page, $asset);
			my($id)  = $self -> param('db') -> session -> param('edit_page_id');
			$page    = $self -> param('db') -> page -> get_page_by_id($id);
			$result  = $self -> build_success_result('delete', $page, $message, $target_div);
		}
	}
	catch
	{
		$result = $self -> build_error_result($page. $_, $target_div);
	};

	# update_page_message_div is on screen (under the Edit Pages tab),
	# because we're displaying a page using page.tx.

	return JSON::XS -> new -> utf8 -> encode({results => $result});

} # End of delete.

# -----------------------------------------------

sub display
{
	my($self) = @_;

	$self -> log(debug => 'display()');

	# These keys are used in the return statement,
	# but should only be displayed in case of error.

	my($page) =
	{
		curent_page => 'N/A',
		homepage    => 'No',
		page_name   => 'N/A',
	};
	my($target_div) = 'update_site_message_div';

	my($design);
	my($result);

	try
	{
		my($message);
		my($site);

		($message, $site, $design) = $self -> process_site_and_design_form('update');

		if ($message)
		{
			$result = $self -> build_error_result($page, $message, $target_div);
		}
		else
		{
			# Success.
			# Note: If the user typed in a new site name, this will
			# call add for the site (effectively) and add for the design.
			# Note: If the user typed in a new design name, this will
			# call update for the site and add for the design.

			$self -> param('db') -> site -> update($site, $design);

			$page    = $self -> edit($site, $design);
			$message = $self -> param('view') -> page -> edit($site, $design, $page);
			$result  = $self -> build_success_result('display', $page, $message, 'update_page_div');
		}
	}
	catch
	{
		$result = $self -> build_error_result($page, $_, $target_div);
	};

	# update_page_div is always on screen (under the Edit Pages tab).
	# It appears there by virtue of being within Initialize.build_head_init().
	# update_site_message_div is on screen (under the Edit Site tab),
	# because we're displaying a site with an Edit button.
	# It appears there by virtue of being within search.tx.

	return JSON::XS -> new -> utf8 -> encode({results => $result});

} # End of display.

# -----------------------------------------------

sub edit
{
	my($self, $site, $design) = @_;

	$self -> log(debug => 'edit()');

	# Default to homepage, if any.

	my($page) = $self -> param('db') -> page -> get_homepage($$site{id}, $$design{id});

	# We save some data so various other subs have access to it.
	# We don't put these in a hidden form field, to stop tampering.

	$self -> param('session') -> param(edit_design_id => $$design{id});
	$self -> param('session') -> param(edit_page_id   => $$page{id});
	$self -> param('session') -> param(edit_site_id   => $$site{id});

	return $page;

} # End of edit.

# -----------------------------------------------

sub update
{
	my($self) = @_;

	$self -> log(debug => 'update()');

	# These keys are used in the return statement,
	# but should only be displayed in case of error.

	my($page) =
	{
		curent_page => 'N/A',
		homepage    => 'No',
		page_name   => 'N/A',
	};
	my($target_div) = 'update_page_message_div';

	my($result);

	try
	{
		my($asset);
		my($message);

		($message, $page, $asset) = $self -> process_page_form('update');

		if (! $message)
		{
			# Success.
			# Note: If the user typed in a new page name, this will
			# call add for the page.

			$message = $self -> param('db') -> page -> update($page, $asset);
			$result  = $self -> build_success_result('update', $page, $message, $target_div);
		}
	}
	catch
	{
		$result = $self -> build_error_result($page, $_, $target_div);
	};

	# update_page_message_div is on screen (under the Edit Pages tab),
	# because we're displaying a page using page.tx.

	return JSON::XS -> new -> utf8 -> encode({results => $result});

} # End of update.

# -----------------------------------------------

1;
