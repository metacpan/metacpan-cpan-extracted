package CGI::Application::Util::Diff::Actions;

use Carp;

use Config::Tiny;

use Hash::FieldHash qw/:all/;

fieldhash my %config => 'config';

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use CGI::Application::Util::Diff::Actions ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(

) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

);

our $VERSION = '1.03';

# -----------------------------------------------

# Encapsulated class data.

{
	my(%_attr_data) =
	(
	 _config_file => '',
	);

	sub _default_for
	{
		my($self, $attr_name) = @_;

		$_attr_data{$attr_name};
	}

	sub _standard_keys
	{
		keys %_attr_data;
	}
}

# -----------------------------------------------

sub get_confirm_action
{
	my($self) = @_;

	return ${$self -> config()}{'global'}{'confirm_action'} || 1;

} # End of get_confirm_action.

# -----------------------------------------------

sub get_dir_actions
{
	my($self) = @_;

	return ${$self -> config()}{'dir'};

} # End of get_dir_actions.

# -----------------------------------------------

sub get_dir_commands
{
	my($self)       = @_;
	my($dir_action) = $self -> get_dir_actions();

	my(%action);
	my($command);
	my($description);

	for my $action (sort keys %$dir_action)
	{
		($command, $description) = split(/\s*=\s*/, $$dir_action{$action});
		$action{$action}         = $command;
	}

	return {%action};

} # End of get_dir_commands.

# -----------------------------------------------

sub get_dir_menu
{
	my($self)       = @_;
	my($dir_action) = $self -> get_dir_actions();

	my(%action);
	my($command);
	my($description);

	for my $action (sort keys %$dir_action)
	{
		($command, $description) = split(/\s*=\s*/, $$dir_action{$action});
		$action{$action}         = $description;
	}

	return {%action};

} # End of get_dir_menu.

# -----------------------------------------------

sub get_file_actions
{
	my($self) = @_;

	return ${$self -> config()}{'file'};

} # End of get_file_actions.

# -----------------------------------------------

sub get_file_commands
{
	my($self)        = @_;
	my($file_action) = $self -> get_file_actions();

	my(%action);
	my($command);
	my($description);

	for my $action (sort keys %$file_action)
	{
		($command, $description) = split(/\s*=\s*/, $$file_action{$action});
		$action{$action}         = $command;
	}

	return {%action};

} # End of get_file_commands.

# -----------------------------------------------

sub get_file_menu
{
	my($self)        = @_;
	my($file_action) = $self -> get_file_actions();

	my(%action);
	my($command);
	my($description);

	for my $action (sort keys %$file_action)
	{
		($command, $description) = split(/\s*=\s*/, $$file_action{$action});
		$action{$action}         = $description;
	}

	return {%action};

} # End of get_file_menu.

# -----------------------------------------------
# We don't check for max_diff_line_count in sub new()
# because the user may not be using the file_diff action.

sub get_max_diff_line_count
{
	my($self) = @_;

	return ${$self -> config()}{'global'}{'max_diff_line_count'} || 100;

} # End of get_max_diff_line_count.

# -----------------------------------------------

sub new
{
	my($class, $arg) = @_;
	my($self)        = bless({}, $class);

	for my $attr_name ($self -> _standard_keys() )
	{
		my($arg_name) = $attr_name =~ /^_(.*)/;

		if (exists($$arg{$arg_name}) )
		{
			$$self{$attr_name} = $$arg{$arg_name};
		}
		else
		{
			$$self{$attr_name} = $self -> _default_for($attr_name);
		}
	}

	# Read the user-supplied or default config file.

	my($path) = $$self{'_config_file'};

	if (! $path)
	{
		my($name) = '.htutil.diff.actions.conf';

		for (keys %INC)
		{
			next if ($_ !~ m|CGI/Application/Util/Diff/Actions.pm|);

			($path = $INC{$_}) =~ s/Actions.pm/$name/;
		}
	}

	$self -> config(Config::Tiny -> read($path) );

	# Check for sections [global], [dir] and [file].

	for my $section (qw/global dir file/)
	{
		if (! ${$self -> config()}{$section})
		{
			Carp::croak "Config file '$path' does not contain the section [$section]";
		}
	}

	return $self;

}	# End of new.

# --------------------------------------------------

1;
