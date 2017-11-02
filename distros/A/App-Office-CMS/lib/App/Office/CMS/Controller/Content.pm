package App::Office::CMS::Controller::Content;

use parent 'App::Office::CMS::Controller';
use strict;
use warnings;

use App::Office::CMS::Util::Validator;

use File::Path 'make_path';

use File::Slurper 'write_text';

use JSON::XS;

use Path::Class; # For file().

use String::Dirify;

use Try::Tiny;

# We don't use Moo because we isa CGI::Application.

our $VERSION = '0.93';

# -----------------------------------------------

sub backup
{
	my($self) = @_;

	$self -> log(debug => 'backup()');

	my($target_div) = 'update_content_message_div';

	my($result);

	try
	{
		my($message, $page, $content) = $self -> process_content_form('update');

		if (! $message)
		{
			# Success.

			$message = $self -> param('db') -> content -> backup($page, $content);
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

} # End of backup.

# -----------------------------------------------

sub build_content_hash
{
	my($self, $valid) = @_;

	$self -> log(debug => 'build_content_hash()');

	my($content) =
	{
		design_id => $self -> param('session') -> param('edit_design_id'),
		page_id   => $self -> param('session') -> param('edit_page_id'),
		site_id   => $self -> param('session') -> param('edit_site_id'),
	};
	my($page) = $self -> param('db') -> page -> get_page_by_id($$content{page_id});

	for my $field_name (qw/body_text head_text/)
	{
		$$content{$field_name} = $$valid{$field_name};
	}

	return ($page, $content);

} # End of build_content_hash.

# -----------------------------------------------

sub build_error_result
{
	my($self, $message, $target_div) = @_;

 	$self -> log(debug => "build_error_result(..., $target_div)");

	return
	{
		message    => $message,
		target_div => $target_div,
	};

} # End of build_error_result.

# -----------------------------------------------

sub build_menu
{
	my($self, $design, $page) = @_;

	$self -> log(debug => 'build_menu()');

	my($tree) = $self -> param('db')-> menu -> get_menu_by_context($$page{context});

	# We use $tree -> daughters to exclude the dummy root node.

	return $self -> build_structure($$design{output_doc_root}, $tree -> daughters);

} # End of build_menu.

# -----------------------------------------------
# Note: Since this method is recursive, we don't log each entry.

sub build_structure
{
	my($self, $output_doc_root, @node) = @_;
	my($item_data)   = [];

	my($file_name);
	my(@daughters);
	my($path);

	for my $i (0 .. $#node)
	{
		($path, $file_name) = $self -> generate_web_page_path($node[$i], 'Unix', $output_doc_root);

		push @$item_data,
		'{',
		'  href:  "' . $file_name . '",',
		'  label: "' . $node[$i] -> name . '",',
		'  type:  "text"';

		@daughters = $node[$i] -> daughters;

		if ($#daughters >= 0)
		{
			$$item_data[$#$item_data] .= ',';

			push @$item_data,
			'  expanded: true,',
			'  children:',
			'  [',
			@{$self -> build_structure($output_doc_root, @daughters)},
			'  ]';
		}

		push @$item_data, $i < $#node ? '},' : '}';
	}

	return $item_data;

} # End of build_structure.

# -----------------------------------------------

sub build_success_result
{
	my($self, $page, $message, $target_div) = @_;

	$self -> log(debug => "build_success_result(..., $target_div)");

	return
	{
		homepage   => $$page{homepage},
		message    => $message,
		target_div => $target_div,
	};

} # End of build_success_result.

# -----------------------------------------------

sub cgiapp_init
{
	my($self) = @_;

	$self -> run_modes([qw/backup generate update/]);

} # End of cgiapp_init.

# -----------------------------------------------

sub display
{
	my($self) = @_;

	$self -> log(debug => 'display()');

	my($target_div) = 'update_page_message_div';

	my($result);

	try
	{
		my($message, $page, $asset) = $self -> process_page_form('edit');

		if (! $message)
		{
			my($site_id)   = $self -> param('session') -> param('edit_site_id');
			my($site)      = $self -> param('db') -> site -> get_site_by_id($site_id);
			my($design_id) = $self -> param('session') -> param('edit_design_id');
			my($design)    = $self -> param('db') -> design -> get_design_by_id($design_id);
			$message       = $self -> param('view') -> content -> edit($site, $design, $page, $asset);
			$result        = $self -> build_success_result($page, $message, 'update_content_div');
		}
	}
	catch
	{
		$result = $self -> build_error_result($_, $target_div);
	};

	# update_content_div is always on screen (under the Edit Content tab).
	# It appears there by virtue of being within Initialize.build_head_init().
	# update_page_message_div is on screen (under the Edit Pages tab),
	# because we're displaying a page with an Edit button.
	# It appears there by virtue of being within page.tx.

	return JSON::XS -> new -> utf8 -> encode({results => $result});

} # End of display.

# -----------------------------------------------

sub generate
{
	my($self) = @_;

	$self -> log(debug => 'generate()');

	my($target_div) = 'update_content_message_div';

	my($result);

	try
	{
		my($message, $page, $content) = $self -> process_content_form('update');

		if (! $message)
		{
			$message = $self -> param('db') -> content -> update($page, $content) . $self -> generate_web_site($page);
			$result  = $self -> build_success_result($page, $message, $target_div);
		}
	}
	catch
	{
		$result = $self -> build_error_result($_, $target_div);
	};

	# update_content_div is always on screen (under the Edit Content tab).
	# It appears there by virtue of being within Initialize.build_head_init().
	# update_page_message_div is on screen (under the Edit Pages tab),
	# because we're displaying a page with an Edit button.
	# It appears there by virtue of being within page.tx.

	return JSON::XS -> new -> utf8 -> encode({results => $result});

} # End of generate.

# -----------------------------------------------
# Warning: Do not add $self.
# Note: Since this method is called per page, we don't log each entry.

sub generate_web_page
{
	my($node, $opt)       = @_;
	my($name)             = $node -> name;
	my($path, $file_name) = $$opt{self} -> generate_web_page_path($node, $$opt{os_type}, $$opt{base_dir});

	# Ignore root node, but keep processing.

	if (! defined $path)
	{
		$$opt{self} -> log(debug => 'Skip root');

		return 1;
	}

	my($error);

	make_path($path, {error => \$error});

	if (@$error)
	{
		for my $item (@$error)
		{
			my($file, $message) = %$item;

			if ($file eq '')
			{
				push @{$$opt{error} }, "Directory error processing page '$name': $message";
			}
			else
			{
				push @{$$opt{error} }, "Directory error creating '$file': $message";
			}
		}

		# Stop processing.

		return 0;
	}

	my($page_id) = ${$node -> attributes}{page_id};
	my($content) = $$opt{self} -> param('db') -> content -> get_content_by_page_id($page_id);

	write_text($file_name, $$opt{self} -> param('view') -> content -> generate
			   (
				$$opt{site},
				$$opt{design},
				$$opt{self} -> param('db') -> page -> get_page_by_id($page_id),
				$$opt{menu},
				$content,
			   ) );

	$$opt{count}++;

	return 1;

} # End of generate_web_page.

# -----------------------------------------------
# Note: Since this method is called per page, we don't log each entry.

sub generate_web_page_path
{
	my($self, $node, $os_type, $base_dir) = @_;
	my($name) = $node -> name;
	my(@path) = reverse $node -> ancestors;

	# Ignore root node, but keep processing.

	if ($#path < 0)
	{
		return (undef, undef);
	}

	# Discard root ancestor.

	shift @path;

	@path          = map{String::Dirify -> dirify($_ -> name)} @path;
	my($path)      = file($base_dir, @path) -> as_foreign($os_type);
	my($file_name) = file($path, String::Dirify -> dirify($name) . '.html') -> as_foreign($os_type) -> stringify;

	$self -> log(debug => $file_name);

	return ($path, $file_name);

} # End of generate_web_page_path.

# -----------------------------------------------

sub generate_web_site
{
	my($self, $page) = @_;

	$self -> log(debug => 'generate_web_site()');

	my($design_id) = $$page{design_id};
	my($design)    = $self -> param('db') -> design -> get_design_by_id($design_id);
	my($site_id)   = $$page{site_id};
	my($site)      = $self -> param('db') -> site -> get_site_by_id($site_id);
	my($base_dir)  = $$design{output_directory};
	my($tree)      = $self -> param('db')-> menu -> get_menu_by_context($$page{context});
	my($opt)       =
	{
		base_dir => $base_dir,
		callback => \&generate_web_page,
		count    => 0,
		_depth   => 0,
		design   => $design,
		error    => [],
		menu     => $self -> build_menu($design, $page),
		os_type  => $self -> param('db') -> get_os_type($$design{os_type_id}),
		self     => $self,
		site     => $site,
	};

	$tree -> walk_down($opt);

	my($result);

	if (@{$$opt{error} })
	{
		for (@{$$opt{error} })
		{
			$self -> log(error => $_);
		}

		# The '. ' is because the caller appends this message to another one.

		$result = '. Failed to generate pages. See log';
	}
	else
	{
		$result = $$opt{count} == 1 ? '1 page' : "$$opt{count} pages";
		$result = ". Generated $result under $base_dir";
	}

	return $result;

} # End of generate_web_site.

# -----------------------------------------------

sub process_content_form
{
	my($self, $action) = @_;

	$self -> log(debug => "process_content_form($action)");

	my($data) = App::Office::CMS::Util::Validator -> new
	(
	 config => $self -> param('config'),
	 db     => $self -> param('db'),
	 query  => $self -> query,
	) -> validate_content;

	my($content);
	my($message);
	my($page);

	if ($$data{_rejects})
	{
		$self -> log(debug => 'Content data is not valid');

		$message => $self -> param('view') -> format_errors($$data{_rejects});
	}
	else
	{
		$self -> log(debug => 'Content data valid');

		($page, $content) = $self -> build_content_hash($data);
	}

	return ($message, $page, $content);

} # End of process_content_form.

# -----------------------------------------------

sub update
{
	my($self) = @_;

	$self -> log(debug => 'update()');

	# Expect the worst.

	my($target_div) = 'update_page_message_div';

	my($result);

	try
	{
		my($message, $page, $content) = $self -> process_content_form('update');

		if (! $message)
		{
			# Success.

			$message = $self -> param('db') -> content -> update($page, $content);
			$result  = $self -> build_success_result($page, $message, 'update_content_message_div');
		}
	}
	catch
	{
		$result = $self -> build_error_result($_, $target_div);
	};

	# update_content_message_div is on screen (under the Edit Content tab)
	# because we're displaying content.
	# update_page_message_div is on screen (under the Edit Pages tab)
	# because we're displaying a page.

	return JSON::XS -> new -> utf8 -> encode({results => $result});

} # End of update.

# -----------------------------------------------

1;
