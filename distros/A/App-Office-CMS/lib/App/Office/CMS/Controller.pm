package App::Office::CMS::Controller;

use parent 'CGI::Application';
use common::sense;

use App::Office::CMS::Util::Config;
use App::Office::CMS::Util::Validator;
use App::Office::CMS::Database;
use App::Office::CMS::View;

use Data::Session;

use JSON::XS;

use Text::Xslate;

# We don't use Moose because we ias CGI::Application.

our $VERSION = '0.92';

# -----------------------------------------------

sub build_page_hash
{
	my($self, $valid) = @_;

	$self -> log(debug => 'build_page_hash()');

	my($page) = {};

	my($field_name);

	# Real data.

	for $field_name (qw/asset_type_id homepage menu_orientation_id name new_name/)
	{
		$$page{$field_name} = $$valid{$field_name};
	}

	# Submit buttons.

	for $field_name (qw/submit_add_menu submit_delete_page submit_extend_menu_left submit_extend_menu_right submit_extend_submenu_down submit_extend_submenu_up submit_update_page/)
	{
		$$page{$field_name} = $$valid{$field_name};
	}

	return $page;

} # End of build_page_hash.

# -----------------------------------------------

sub build_site_hash
{
	my($self, $valid) = @_;

	$self -> log(debug => 'build_site_hash()');

	my($site) =
	{
		menu_orientation_id => 4, # Vertical.
		os_type_id          => 3, # Unix.
	};

	for my $field_name (qw/design_name name new_name output_directory output_doc_root/)
	{
		$$site{$field_name} = $$valid{$field_name};
	}

	return $site;

} # End of build_site_hash.

# -----------------------------------------------

sub cgiapp_prerun
{
	my($self, $rm) = @_;

	# Can't call, since db's logger not yet set up.
	#$self -> log(debug => 'cgiapp_prerun()');

	$self -> param(config => App::Office::CMS::Util::Config -> new -> config);
	$self -> param(db     => App::Office::CMS::Database -> new
	(
	 config => $self -> param('config'),
	) );

	# Set up the session. To simplify things we always use
	# CGI::Session, and ignore the PSGI alternative.

	my($config) = $self -> param('config');
	my($q)      = $self -> query;

	$self -> param(session =>
	Data::Session -> new
	(
		data_source => $$config{dsn},
		dbh         => $self -> param('db') -> dbh,
		name        => 'sid',
		pg_bytea    => $$config{pg_bytea} || 0,
		pg_text     => $$config{pg_text}  || 0,
		query       => $q,
		table_name  => $$config{session_table_name},
		type        => $$config{session_driver},
	) );

	# Set up a few more things.

	$self -> param('db') -> set_session($self -> param('session') );
	$self -> param
	(
	 templater =>
	   Text::Xslate -> new
	   (
		input_layer => '',
		path        => ${$self -> param('config')}{template_path},
	   )
	);

	# Other controllers add their own run modes.

	$self -> run_modes([qw/display/]);
	$self -> tmpl_path(${$self -> param('config')}{template_path});

	# Log the CGI form parameters.

	$self -> log(info  => '');
	$self -> log(info  => $q -> url(-full => 1, -path => 1) );
	$self -> log(info  => "Param: $_: " . $q -> param($_) ) for grep{! /^(?:body_text|head_text)$/} $q -> param;
	$self -> log(info  => 'Session id: ' . $self -> param('session') -> id);
	$self -> log(debug => 'tmpl_path: ' . $self -> tmpl_path);

	# Set up the view.

	$self -> param(view => App::Office::CMS::View -> new
	(
	 config      => $self -> param('config'),
	 db          => $self -> param('db'),
	 form_action => $self -> query -> url(-absolute => 1),
	 session     => $self -> param('session'),
	 templater   => $self -> param('templater'),
	 tmpl_path   => $self -> tmpl_path,
	) );

} # End of cgiapp_prerun.

# -----------------------------------------------

sub check_page_name
{
	my($self, $page, $action) = @_;
	$action ||= '';

	$self -> log(debug => "check_page_name($$page{name}, $action)");

	my($design_id)  = $self -> param('session') -> param('edit_design_id');
	my($site_id)    = $self -> param('session') -> param('edit_site_id');
	my($page_match) = $self -> param('db') -> page -> get_page_by_exact_name($site_id, $design_id, $$page{name});

	my($asset);
	my($message);

	if ($page_match)
	{
		# Firstly, prepare new name just in case we need it.

		$$page_match{new_name} = $$page{new_name};

		# Update user's choices.
		# Values for $action, and their meanings when page name matches:
		# o add    => It's not an add, it's an update
		# o click  => The user is changing pages via the Javascript menu
		# o delete => It's a delete
		# o edit   => The user is editing content
		# o update => It's an update

		if ($action =~ /(?:add|update)/)
		{
			$asset                 = $self -> param('db') -> asset -> get_asset_by_page_id($$page_match{id});
			$$asset{asset_type_id} = $$page{asset_type_id};
			$$page_match{homepage} = $$page{homepage};
		}
	}
	elsif ($action =~ /(?:add|update)/)
	{
		my($design_id) = $self -> param('session') -> param('edit_design_id');
		my($design)    = $self -> param('db') -> design -> get_design_by_id($design_id);
		my($site_id)   = $self -> param('session') -> param('edit_site_id');
		my($site)      = $self -> param('db') -> site -> get_site_by_id($site_id);
		$page_match    = $self -> param('db') -> build_default_page($site, $design, $$page{name});
		$asset         = $self -> param('db') -> build_default_asset($page_match);

		# Update user's choices.

		$$asset{asset_type_id} = $$page{asset_type_id};
		$$page_match{homepage} = $$page{homepage};
	}
	else
	{
		$message = "Error: No page matches the name '$$page{name}'";
	}

	# Note: By returning $page_match, we lose the CGI form fields.

	return ($message, $page_match, $asset);

} # End of check_page_name.

# -----------------------------------------------

sub check_site_and_design_names
{
	my($self, $site, $action) = @_;
	$action ||= '';

	$self -> log(debug => "check_site_and_design_names($$site{name}, $action)");

	# Did the client submit an existing site?

	my($site_match) = $self -> param('db') -> site -> get_site_by_exact_name($$site{name});

	my($design);
	my($message);

	if ($site_match)
	{
		# Firstly, prepare new name just in case the client clicked 'Duplicate site'.

		$$site_match{new_name} = $$site{new_name};

		# Secondly, did the client submit an existing design?

		$design = $self -> param('db') -> design -> get_design_by_exact_name($$site_match{id}, $$site{design_name});

		# Thirdly, prepare new name just in case the client clicked 'Duplicate design'.
		# But, we don't need to put the new name in the design object because
		# Controller::Design.duplicate() passes $site_match to Database::Design.duplicate().
		# Note: The client must specify an existing design for 'Duplicate design' to work.

		if ($design)
		{
			# Update user's choices.

			#$$design{menu_orientation_id} = $$site{menu_orientation_id};
			#$$design{os_type_id}          = $$site{os_type_id};
			$$design{output_directory}    = $$site{output_directory};
			$$design{output_doc_root}     = $$site{output_doc_root};
		}
		elsif ($action =~ /(?:add|duplicate_site|update)/)
		{
			# When duplicating a site, the default design manufactured here is ignored.

			$design = $self -> param('db') -> build_default_design($$site_match{id}, $$site{design_name}, $$site{menu_orientation_id}, $$site{os_type_id}, $$site{output_directory}, $$site{output_doc_root});
		}
		else
		{
			$message = "Error: No design matches the name '$$site{design_name}' for site '$$site{name}'";
		}
	}
	elsif ($action =~ /(?:add|update)/)
	{
		$site_match = $self -> param('db') -> build_default_site($$site{name});
		$design     = $self -> param('db') -> build_default_design(0, $$site{design_name}, $$site{menu_orientation_id}, $$site{os_type_id}, $$site{output_directory}, $$site{output_doc_root});
	}
	else
	{
		$message = "Error: No site matches the name '$$site{name}'";
	}

	# Note: By returning $site_match, we loose the CGI form fields.

	return ($message, $site_match, $design);

} # End of check_site_and_design_names.

# -----------------------------------------------

sub log
{
	my($self, $level, $s) = @_;

	$self -> param('db') -> log($level, $s);

} # End of log.

# -----------------------------------------------

sub process_page_form
{
	my($self, $action) = @_;

	$self -> log(debug => "process_page_form($action)");

	my($data) = App::Office::CMS::Util::Validator -> new
	(
	 config => $self -> param('config'),
	 db     => $self -> param('db'),
	 query  => $self -> query,
	) -> validate_page;

	my($asset);
	my($message);
	my($page);

	if ($$data{_rejects})
	{
		$self -> log(debug => 'Page data is not valid');

		$message => $self -> param('view') -> format_errors($$data{_rejects});
	}
	else
	{
		$self -> log(debug => 'Page data is valid');

		$page                     = $self -> build_page_hash($data);
		($message, $page, $asset) = $self -> check_page_name($page, $action);
	}

	return ($message, $page, $asset);

} # End of process_page_form.

# -----------------------------------------------

sub process_site_and_design_form
{
	my($self, $action) = @_;

	$self -> log(debug => "process_site_and_design_form($action)");

	my($data) = App::Office::CMS::Util::Validator -> new
	(
	 config => $self -> param('config'),
	 db     => $self -> param('db'),
	 query  => $self -> query,
	) -> validate_site_and_design;

	my($design);
	my($message);
	my($site);

	if ($$data{_rejects})
	{
		$self -> log(debug => 'Site and design data is not valid');

		$message = $self -> param('view') -> format_errors($$data{_rejects});
	}
	else
	{
		$self -> log(debug => 'Site and design data is valid');

		$site                      = $self -> build_site_hash($data);
		($message, $site, $design) = $self -> check_site_and_design_names($site, $action);
	}

	return ($message, $site, $design);

} # End of process_site_and_design_form.

# -----------------------------------------------

sub teardown
{
	my($self) = @_;

	$self -> log(debug => 'teardown()');

	# This is mandatory under Plack.

	$self -> param('session') -> flush;

} # End of teardown.

# -----------------------------------------------

1;
