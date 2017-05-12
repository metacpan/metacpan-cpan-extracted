package App::GitHooks;

use strict;
use warnings;

# Unbuffer output to display it as quickly as possible.
local $| = 1;

# External dependencies.
use Carp qw( carp croak );
use Class::Load qw();
use Config::Tiny qw();
use Data::Validate::Type qw();
use Data::Dumper qw( Dumper );
use File::Basename qw();
use Git::Repository qw();
use Module::Pluggable
	require  => 1,
	sub_name => '_search_plugins';
use Term::ANSIColor qw();
use Text::Wrap qw();
use Try::Tiny qw( try catch finally );
use Storable qw();

# Internal dependencies.
use App::GitHooks::Config;
use App::GitHooks::Constants qw( :HOOK_EXIT_CODES );
use App::GitHooks::Plugin;
use App::GitHooks::StagedChanges;
use App::GitHooks::Terminal;


=head1 NAME

App::GitHooks - Extensible plugins system for git hooks.


=head1 VERSION

Version 1.9.0

=cut

our $VERSION = '1.9.0';


=head1 DESCRIPTION

C<App::GitHooks> is an extensible and easy to configure git hooks framework that supports many plugins.

Here's an example of it in action, running the C<pre-commit> hook checks before
the commit message can be entered:

=begin html

<div><img src="https://raw.github.com/guillaumeaubert/App-GitHooks/master/img/app-githooks-example-success.png"></div>

=end html

Here is another example, with a Perl file that fails compilation this time:

=begin html

<div><img src="https://raw.github.com/guillaumeaubert/App-GitHooks/master/img/app-githooks-example-failure.png"></div>

=end html


=head1 SYNOPSIS

=over 4

=item 1.

Install this distribution (with cpanm or your preferred CPAN client):

	cpanm App::GitHooks

=item 2.

Install the plugins you are interested in (with cpanm or your prefered CPAN
client), as C<App::GitHooks> does not bundle them. See the list of plugins
below, but for example:

	cpanm App::GitHooks::Plugin::BlockNOCOMMIT
	cpanm App::GitHooks::Plugin::DetectCommitNoVerify
	...

=item 3.

Go to the git repository for which you want to set up git hooks, and run:

	githooks install

=item 4.

Enjoy!

=back


=head1 GIT REQUIREMENTS

L<App::GitHooks> requires git v1.7.4.1 or above.


=head1 VALID GIT HOOK NAMES

=over 4

=item * applypatch-msg

=item * pre-applypatch

=item * post-applypatch

=item * pre-commit

=item * prepare-commit-msg

=item * commit-msg

=item * post-commit

=item * pre-rebase

=item * post-checkout

=item * post-merge

=item * pre-receive

=item * update

=item * post-receive

=item * post-update

=item * pre-auto-gc

=item * post-rewrite

=back

=cut

# List of valid git hooks.
# From https://www.kernel.org/pub/software/scm/git/docs/githooks.html
our $HOOK_NAMES =
[
	qw(
		applypatch-msg
		commit-msg
		post-applypatch
		post-checkout
		post-commit
		post-merge
		post-receive
		post-rewrite
		post-update
		pre-applypatch
		pre-auto-gc
		pre-commit
		pre-push
		pre-rebase
		pre-receive
		prepare-commit-msg
		update
	)
];


=head1 OFFICIALLY SUPPORTED PLUGINS

=over 4

=item * L<App::GitHooks::Plugin::BlockNOCOMMIT>

Prevent committing code with #NOCOMMIT mentions.

=item * L<App::GitHooks::Plugin::BlockProductionCommits>

Prevent commits in a production environment.

=item * L<App::GitHooks::Plugin::DetectCommitNoVerify>

Find out when someone uses --no-verify and append the pre-commit checks to the
commit message.

=item * L<App::GitHooks::Plugin::ForceRegularUpdate>

Force running a specific tool at regular intervals.

=item * L<App::GitHooks::Plugin::MatchBranchTicketID>

Detect discrepancies between the ticket ID specified by the branch name and the
one in the commit message.

=item * L<App::GitHooks::Plugin::PerlCompile>

Verify that Perl files compile without errors.

=item * L<App::GitHooks::Plugin::PerlCritic>

Verify that all changes and addition to the Perl files pass PerlCritic checks.

=item * L<App::GitHooks::Plugin::PerlInterpreter>

Enforce a specific Perl interpreter on the first line of Perl files.

=item * L<App::GitHooks::Plugin::PgBouncerAuthSyntax>

Verify that the syntax of PgBouncer auth files is correct.

=item * L<App::GitHooks::Plugin::PrependTicketID>

Derive a ticket ID from the branch name and prepend it to the commit-message.

=item * L<App::GitHooks::Plugin::RequireCommitMessage>

Require a commit message.

=item * L<App::GitHooks::Plugin::RequireTicketID>

Verify that staged Ruby files compile.

=item * L<App::GitHooks::Plugin::ValidatePODFormat>

Validate POD format in Perl and POD files.

=back


=head1 CONTRIBUTED PLUGINS

=over 4

=item * L<App::GitHooks::Plugin::RubyCompile>

Verify that staged Ruby files compile.

=item * L<App::GitHooks::Plugin::PreventTrailingWhitespace>

Prevent trailing whitespace from being committed.

=back


=head1 CONFIGURATION OPTIONS

=head2 Configuration format

L<App::GitHooks> uses L<Config::Tiny>, so the configuration should follow the
following format:

	general_key_1 = value
	general_key_2 = value

	[section_1]
	section_1_key 1 = value

The file is divided between the global configuration options at the beginning
of the file (such as C<general_key_1> above) and plugin specific configuration
options which are located in distinct sections (such as C<section_1_key> in the
C<[section_1]> section).


=head2 Configuration file locations

L<App::GitHooks> supports setting custom options by creating one of the
following files, which are searched in descending order of preference:

=over 4

=item *

A file of any name anywhere on your system, if you set the environment variable
C<GITHOOKSRC_FORCE> to its path.

Note that you should normally use C<GITHOOKSRC>. This option is provided mostly
for testing purposes, when configuration options for testing in a reliable
manner are of the utmost importance and take precedence over any
repository-specific settings.

=item *

A C<.githooksrc> file at the root of the git repository.

The settings will then only apply to that repository.

=item *

A file of any name anywhere on your system, if you set the environment variable
C<GITHOOKSRC> to its path.

Note that C<.githooksrc> files at the top of a repository or in a user's home
directory will take precedence over a file specified by the C<GITHOOKSRC>
environment variable.

=item *

A C<.githooksrc> file in the home directory of the current user.

The settings will then apply to all the repositories that have hooks set up.
Note that if C<.githooksrc> file is defined at the root of a repository, that
configuration file will take precedence over the one defined in the home
directory of the current user (as it is presumably more specific). Auto-merge
of options across multiple C<.githooksrc> files in an inheritance fashion is
not currently supported.

=back


=head2 General configuration options

=over 4

=item * project_prefixes

A comma-separated list of project prefixes, in case you want to use this in
C<extract_ticket_id_from_commit> or C<extract_ticket_id_from_branch>.

	project_prefixes = OPS, DEV

=item * extract_ticket_id_from_commit

A regular expression with _one_ capturing group that will be applied to the
first line of a commit message to extract the ticket ID referenced, if there is
one.

	extract_ticket_id_from_commit = /^($project_prefixes-\d+|--): /

=item * extract_ticket_id_from_branch

A regular expression with _one_ capturing group that will be applied to branch
names to extract a ticket ID. This allows creating one branch per ticket and
having the hooks check that the commit messages and the branch names are in
sync.

	extract_ticket_id_from_branch = /^($project_prefixes-?\d+)/

=item * normalize_branch_ticket_id

A replacement expression that normalizes the ticket ID captured with
C<extract_ticket_id_from_branch>.

	normalize_branch_ticket_id = s/^(.*?)-?(\d+)$/\U$1-$2/

=item * skip_directories

A regular expression to filter the directory names that should be skipped when
analyzing files as part of file-level checks.

	skip_directories = /^cpan(?:-[^\/]+)?\//

=item * force_plugins

A comma-separated list of the plugins that must be present on the system and
will be executed. If any plugins from this list are missing, the action will
error out. If any other plugins not in this list are installed on the system,
they will be ignored.

	force_plugins = App::GitHooks::Plugin::ValidatePODFormat, App::GitHooks::Plugin::RequireCommitMessage

=item * min_app_githooks_version

Specify the minimum version of App::GitHooks.

	min_app_githooks_version = 1.9.0

=back


=head2 Testing-specific options

=over 4

=item * limit_plugins

Deprecated. Use C<force_plugins> instead.

=item * force_interactive

Force the application to consider that the terminal is interactive (`1`) or
non-interactive (`0`) independently of whether the actual STDOUT is interactive
or not.

=item * force_use_colors

Force the output to use colors (`1`) or to not use colors (`0`) independently
of the ability of STDOUT to display colors.

=item * force_is_utf8

Allows the output to use utf-8 characters (`1`) or not (`0`), independently of
whether the output declares supporting utf-8.

=item * commit_msg_no_edit

Allows skipping the loop to edit the message when the commit message checks
failed.

=back


=head1 ENVIRONMENT VARIABLES

=head2 GITHOOKS_SKIP

Comma separated list of hooks to skip. A warning is issued for each hook that
would otherwise be triggered.

	GITHOOKS_SKIP=pre-commit,update

=head2 GITHOOKS_DISABLE

Works similarly to C<GITHOOKS_SKIP>, but it skips all the possible hooks. Set
it to a true value, e.g. 1.

	GITHOOKS_DISABLE=1

=head2 GITHOOKSRC

Contains path to a custom configuration file, see "Configuration file
locations" above.

=head2 GITHOOKSRC_FORCE

Similar to C<GITHOOKSRC> but with a higher priority. See "Configuration file
locations" above.


=head1 FUNCTIONS

=head2 run()

Run the specified hook.

	App::GitHooks::run(
		name      => $name,
		arguments => \@arguments,
	);

Arguments:

=over 4

=item * name I<(mandatory)>

The name of the git hook calling this class. See the "VALID GIT HOOK NAMES"
section for acceptable values.

=item * arguments I<(optional)>

An arrayref of arguments passed originally to the git hook.

=item * exit I<(optional, default 1)>

Indicate whether the method should exit (1) or simply return the exit status
without actually exiting (0).

=back

=cut

sub run
{
	my ( $class, %args ) = @_;
	my $name = delete( $args{'name'} );
	my $arguments = delete( $args{'arguments'} );
	my $exit = delete( $args{'exit'} ) // 1;

	my $exit_code =
	try
	{
		croak 'Invalid argument(s): ' . join( ', ', keys %args )
			if scalar( keys %args ) != 0;

		# Clean up hook name in case we were passed a file path.
		$name = File::Basename::fileparse( $name );

		# Validate hook name.
		croak 'A hook name must be passed'
			if !defined( $name );
		croak "Invalid hook name $name"
			if scalar( grep { $_ eq $name } @$HOOK_NAMES ) == 0;

		if (my $env_var = _should_skip( $name )) {
			carp "Hook $name skipped because of $env_var";
			return $HOOK_EXIT_SUCCESS;
		}

		# Validate arguments.
		croak 'Unknown argument(s): ' . join( ', ', keys %args )
			if scalar( keys %args ) != 0;

		# Load the hook class.
		my $hook_class = "App::GitHooks::Hook::" . _to_camelcase( $name );
		Class::Load::load_class( $hook_class );

		# Create a new App instance to hold the various data.
		my $self = $class->new(
			arguments => $arguments,
			name      => $name,
		);

		# Force the output to match the terminal encoding.
		my $terminal = $self->get_terminal();
		my $terminal_encoding = $terminal->get_encoding();
		binmode( STDOUT, "encoding($terminal_encoding)" )
			if $terminal->is_utf8();

		# Run the hook.
		my $hook_exit_code = $hook_class->run(
			app => $self,
		);
		croak "$hook_class ran successfully but did not return an exit code."
			if !defined( $hook_exit_code );

		return $hook_exit_code;
	}
	catch
	{
		chomp( $_ );
		print STDERR "Error detected in hook: >$_<.\n";
		return $HOOK_EXIT_FAILURE;
	};

	if ( $exit )
	{
		exit( $exit_code );
	}
	else
	{
		return $exit_code;
	}
}


=head1 METHODS

=head2 new()

Create a new C<App::GitHooks> object.

	my $app = App::GitHooks->new(
		name      => $name,
		arguments => \@arguments,
	);

Arguments:

=over 4

=item * name I<(mandatory)>

The name of the git hook calling this class. See the "VALID GIT HOOK NAMES"
section for acceptable values.

=item * arguments I<(optional)>

An arrayref of arguments passed originally to the git hook.

=back

=cut

sub new
{
	my ( $class, %args ) = @_;
	my $name = delete( $args{'name'});
	my $arguments = delete( $args{'arguments'} );

	# Defaults.
	$arguments = []
		if !defined( $arguments );

	# Check arguments.
	croak "The 'argument' parameter must be an arrayref"
		if !Data::Validate::Type::is_arrayref( $arguments );
	croak "The argument 'name' is mandatory"
		if !defined( $name );
	croak "Invalid hook name $name"
		if scalar( grep { $_ eq $name } @$HOOK_NAMES ) == 0;
	croak 'The following argument(s) are not valid: ' . join( ', ', keys %args )
		if scalar( keys %args ) != 0;

	# Create object.
	my $self = bless(
		{
			plugins               => undef,
			force_non_interactive => 0,
			terminal              => App::GitHooks::Terminal->new(),
			arguments             => $arguments,
			hook_name             => $name,
			repository            => undef,
			use_colors            => 1,
		},
		$class,
	);

	# Look up testing overrides.
	my $config = $self->get_config();

	my $force_use_color = $config->get( 'testing', 'force_use_colors' );
	$self->use_colors( $force_use_color )
		if defined( $force_use_color );

	my $force_is_utf8 = $config->get( 'testing', 'force_is_utf8' );
	$self->get_terminal()->is_utf8( $force_is_utf8 )
		if defined( $force_is_utf8 );

	return $self;
}


=head2 clone()

Clone the current object and override its properties with the arguments
specified.

	my $cloned_app = $app->clone(
		name => $hook_name, # optional
	);

=over 4

=item * name I<(optional)>

The name of the invoking hook.

=back

=cut

sub clone
{
	my ( $self, %args ) = @_;
	my $name = delete( $args{'name'} );
	croak 'Invalid argument(s): ' . join( ', ', keys %args )
		if scalar( keys %args ) != 0;

	# Clone the object.
	my $cloned_app = Storable::dclone( $self );

	# Overrides.
	if ( defined( $name ) )
	{
		croak "Invalid hook name $name"
			if scalar( grep { $_ eq $name } @$HOOK_NAMES ) == 0;

		$cloned_app->{'hook_name'} = $name;
	}

	return $cloned_app;
}


=head2 get_hook_plugins()

Return an arrayref of all the plugins installed and available for a specific
git hook on the current system.

	my $plugins = $app->get_hook_plugins(
		$hook_name
	);

Arguments:

=over 4

=item * $hook_name

The name of the git hook for which to find available plugins.

=back

=cut

sub get_hook_plugins
{
	my ( $self, $hook_name ) = @_;

	# Check parameters.
	croak "A git hook name is required"
		if !defined( $hook_name );

	# Handle both - and _ in the hook name.
	$hook_name =~ s/-/_/g;

	# Searching for plugins is expensive, so we cache it here.
		$self->{'plugins'} = $self->get_all_plugins()
			if !defined( $self->{'plugins'} );

	return $self->{'plugins'}->{ $hook_name } // [];
}


=head2 get_all_plugins()

Return a hashref of the plugins available for every git hook.

	my $all_plugins = $self->get_all_plugins();

=cut

sub get_all_plugins
{
	my ( $self ) = @_;
	my $config = $self->get_config();

	# Find all available plugins regardless of the desired target hook, using
	# Module::Pluggable.
	my @discovered_plugins = __PACKAGE__->_search_plugins();

	# Warn about deprecated 'limit_plugins' config option.
	my $limit_plugins = $config->get( 'testing', 'limit_plugins' );
	if ( defined( $limit_plugins ) )
	{
		carp "The configuration option 'limit_plugins' under the [testing] section "
			. "is deprecated, please switch to using 'force_plugins' under the general "
			. "configuration section as soon as possible";
	}

	# If the environment restricts the list of plugins to run, we use that.
	# Otherwise, we exclude test plugins.
	my $force_plugins = $config->get( '_', 'force_plugins' )
		// $limit_plugins
		// '';
	my @plugins = ();
	if ( $force_plugins =~ /\w/ )
	{
		my %forced_plugins =
			map { $_ => 1 }
			# Prepend App::GitHooks::Plugin:: to the plugin name if omitted.
			map { $_ =~ /^App/ ? $_ : "App::GitHooks::Plugin::$_" }
			# Split the comma-separated list.
			split( /(?:\s+|\s*,\s*)/, $force_plugins );

		foreach my $plugin ( @discovered_plugins )
		{
			# Only add plugins listed in the config file.
			next if !$forced_plugins{ $plugin };

			push( @plugins, $plugin );
			delete( $forced_plugins{ $plugin } );
		}

		# If plugins listed in the config file are not found on the system, don't
		# continue.
		if ( scalar( keys %forced_plugins ) != 0 )
		{
			croak sprintf(
				"The following plugins must be installed on your system, per the "
				. "'force_plugins' directive in your githooksrc config file: %s",
				join( ', ', keys %forced_plugins ),
			);
		}
	}
	else
	{
		foreach my $plugin ( @discovered_plugins )
		{
			next if $plugin =~ /^\QApp::GitHooks::Plugin::Test::\E/x;
			push( @plugins, $plugin );
		}
	}
	#print STDERR Dumper( \@plugins );

	# Parse each plugin to find out which hook(s) they apply to.
	my $all_plugins = {};
	foreach my $plugin ( @plugins )
	{
		# Load the plugin class.
		Class::Load::load_class( $plugin );

		# Store the list of plugins available for each hook.
		my $hooks_declared;
		foreach my $hook ( @{ $App::GitHooks::Plugin::SUPPORTED_SUBS } )
		{
			next if !$plugin->can( 'run_' . $hook );
			$hooks_declared = 1;

			$all_plugins->{ $hook } //= [];
			push( @{ $all_plugins->{ $hook } }, $plugin );
		}

		# Alert if the plugin didn't declare any hook handling subroutines -
		# that's probably the sign of a typo in a subroutine name.
		carp "The plugin $plugin does not declare any hook handling subroutines, check for typos in sub names?"
			if !$hooks_declared;
	}

	return $all_plugins;
}


=head2 get_config()

Retrieve the configuration information for the current project.

	my $config = $app->get_config();

=cut

sub get_config
{
	my ( $self ) = @_;

	if ( !defined( $self->{'config'} ) )
	{
		my $config_file;
		my $config_source;
		# For testing purposes, provide a way to enforce a specific .githooksrc
		# file regardless of how anything else is set up on the machine.
		if ( defined( $ENV{'GITHOOKSRC_FORCE'} ) && ( -e $ENV{'GITHOOKSRC_FORCE'} ) )
		{
			$config_source = 'GITHOOKSRC_FORCE environment variable';
			$config_file = $ENV{'GITHOOKSRC_FORCE'};
		}
		# First, use repository-specific githooksrc files.
		elsif ( -e '.githooksrc' )
		{
			$config_source = '.githooksrc at the root of the repository';
			$config_file = '.githooksrc';
		}
		# Fall back on the GITHOOKSRC variable.
		elsif ( defined( $ENV{'GITHOOKSRC'} ) && ( -e $ENV{'GITHOOKSRC'} ) )
		{
			$config_source = 'GITHOOKSRC environment variable';
			$config_file = $ENV{'GITHOOKSRC'};
		}
		# Fall back on the home directory of the user.
		elsif ( defined( $ENV{'HOME'} ) && ( -e $ENV{'HOME'} . '/.githooksrc' ) )
		{
			$config_source = '.githooksrc in the home directory';
			$config_file = $ENV{'HOME'} . '/.githooksrc';
		}

		$self->{'config'} = App::GitHooks::Config->new(
			defined( $config_file )
				? ( file => $config_file, source => $config_source )
				: (),
		);
	}

	# Enforce the specifying of min version of App::GitHooks
	my $min_version = $self->{'config'}->get('_','min_app_githooks_version');
	croak "Requires at least App::Githooks version $min_version, you have version $VERSION"
		if $min_version && $min_version gt $VERSION;

	return $self->{'config'};
}


=head2 force_non_interactive()

By default C<App::GitHooks> detects whether it is running in interactive mode,
but this allows forcing it to run in non-interactive mode.

	# Retrieve the current setting.
	my $force_non_interactive = $app->force_non_interactive();

	# Force non-interactive mode.
	$app->force_non_interactive( 1 );

	# Go back to the default behavior of detecting the current mode.
	$app->force_non_interactive( 0 );

=cut

sub force_non_interactive
{
	my ( $self, $value ) = @_;

	if ( defined( $value ) )
	{
		if ( $value =~ /^(?:0|1)$/ )
		{
			$self->{'force_non_interactive'} = $value;
		}
		else
		{
			croak 'Invalid argument';
		}
	}

	return $self->{'force_non_interactive'};
}


=head2 get_failure_character()

Return a character to use to indicate a failure.

	my $failure_character = $app->get_failure_character()

=cut

sub get_failure_character
{
	my ( $self ) = @_;

	return $self->get_terminal()->is_utf8()
		? "\x{00D7}"
		: "x";
}


=head2 get_success_character()

Return a character to use to indicate a success.

	my $success_character = $app->get_success_character()

=cut

sub get_success_character
{
	my ( $self ) = @_;

	return $self->get_terminal()->is_utf8()
		? "\x{2713}"
		: "o";
}


=head2 get_warning_character()

Return a character to use to indicate a warning.

	my $warning_character = $app->get_warning_character()

=cut

sub get_warning_character
{
	my ( $self ) = @_;

	return $self->get_terminal()->is_utf8()
		? "\x{26A0}"
		: "!";
}


=head2 get_staged_changes()

Return a C<App::GitHooks::StagedChanges> object corresponding to the changes
staged in the current project.

	my $staged_changes = $app->get_staged_changes();

=cut

sub get_staged_changes
{
	my ( $self ) = @_;

	if ( !defined( $self->{'staged_changes'} ) )
	{
		$self->{'staged_changes'} = App::GitHooks::StagedChanges->new(
			app => $self,
		);
	}

	return $self->{'staged_changes'};
}


=head2 use_colors()

Allows disabling the use of colors in C<App::GitHooks>'s output.

	# Retrieve the current setting.
	my $use_colors = $app->use_colors();

	# Disable colors in the output.
	$app->use_colors( 0 );

=cut

sub use_colors
{
	my ( $self, $value ) = @_;

	if ( defined( $value ) )
	{
		$self->{'use_colors'} = $value;
	}

	return $self->{'use_colors'};
}


=head1 ACCESSORS

=head2 get_repository()

Return the underlying C<Git::Repository> object for the current project.

	my $repository = $app->get_repository();

=cut

sub get_repository
{
	my ( $self ) = @_;

	$self->{'repository'} //= Git::Repository->new();

	return $self->{'repository'};
}


=head2 get_remote_name()

Get the name of the repository.

	my $remote_name = $app->get_remote_name();

=cut

sub get_remote_name
{
	my ( $app ) = @_;
	my $repository = $app->get_repository();

	# Retrieve the remote path.
	my $remote = $repository->run( qw( config --get remote.origin.url ) ) // '';

	# Extract the remote name.
	my ( $remote_name ) = ( $remote =~ /\/(.*?)\.git$/i );
	$remote_name //= '(no remote found)';

	return $remote_name;
}


=head2 get_hook_name

Return the name of the git hook that called the current instance.

	my $hook_name = $app->get_hook_name();

=cut

sub get_hook_name
{
	my ( $self ) = @_;

	return $self->{'hook_name'};
}


=head2 get_command_line_arguments()

Return the arguments passed originally to the git hook.

	my $command_line_arguments = $app->get_command_line_arguments();

=cut

sub get_command_line_arguments
{
	my ( $self ) = @_;

	return $self->{'arguments'} // [];
}


=head2 get_terminal()

Return the C<App::GitHooks::Terminal> object associated with the current
instance.

	my $terminal = $app->get_terminal();

=cut

sub get_terminal
{
	my ( $self ) = @_;

	return $self->{'terminal'};
}


=head1 DISPLAY METHODS

=head2 wrap()

Format information while respecting the format width and indentation.

	my $string = $app->wrap( $information, $indent );

=cut

sub wrap
{
	my ( $self, $information, $indent ) = @_;
	$indent //= '';

	return
		if !defined( $information );

	my $terminal_width = $self->get_terminal()->get_width();
	if ( defined( $terminal_width ) )
	{
		local $Text::Wrap::columns = $terminal_width; ## no critic (Variables::ProhibitPackageVars)

		return Text::Wrap::wrap(
			$indent,
			$indent,
			$information,
		);
	}
	else
	{

		return join(
			"\n",
			map
				{ defined( $_ ) && $_ ne '' ? $indent . $_ : $_ } # Don't indent blank lines.
				split( /\n/, $information, -1 )                   # Keep trailing \n's.
		);
	}
}


=head2 color()

Print text with colors.

	$app->color( $color, $text );

=cut

sub color
{
	my ( $self, $color, $string ) = @_;

	return $self->use_colors()
		? Term::ANSIColor::colored( [ $color ], $string )
		: $string;
}


=head1 PRIVATE FUNCTIONS

=head2 _to_camelcase()

Convert a dash-separated string to camelcase.

	my $camelcase_string = App::GitHooks::_to_camelcase( $string );

This function is useful to convert git hook names (commit-msg) to module names
(CommitMsg).

=cut

sub _to_camelcase
{
	my ( $name ) = @_;

	$name =~ s/-(.)/\U$1/g;
	$name = ucfirst( $name );

	return $name;
}


=head2 _should_skip()

See the environment variables GITHOOKS_SKIP and GITHOOKS_DISABLE above. This
function returns the variable name that would be the reason to skip the given
hook, or nothing.

	return if _should_skip( $name );

=cut

sub _should_skip
{
	my ( $name ) = @_;
	return unless exists $ENV{'GITHOOKS_SKIP'}
	           || exists $ENV{'GITHOOKS_DISABLE'};

	return 'GITHOOKS_DISABLE' if $ENV{'GITHOOKS_DISABLE'};

	my %skip;
	@skip{ split /,/, $ENV{'GITHOOKS_SKIP'} } = ();
	return exists $skip{ $name } && 'GITHOOKS_SKIP';
}


=head1 NOTES

=head2 Manual installation

Symlink your git hooks under .git/hooks to a file with the following content:

	#!/usr/bin/env perl

	use strict;
	use warnings;

	use App::GitHooks;

	App::GitHooks->run(
			name      => $0,
			arguments => \@ARGV,
	);

All you need to do then is install the plugins you are interested in!

This distribution also includes a C<hooks/> directory that you can symlink /
copy to C<.git/hooks/> instead , to get all the hooks set up properly in one
swoop.

Important: adjust C</usr/bin/env perl> as needed, if that line is not a valid
interpreter, your git actions will fail with C<error: cannot run
.git/hooks/[hook name]: No such file or directory>.


=head1 BUGS

Please report any bugs or feature requests through the web interface at
L<https://github.com/guillaumeaubert/App-GitHooks/issues/new>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc App::GitHooks


You can also look for information at:

=over

=item * GitHub's request tracker

L<https://github.com/guillaumeaubert/App-GitHooks/issues>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/app-githooks>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/app-githooks>

=item * MetaCPAN

L<https://metacpan.org/release/App-GitHooks>

=back


=head1 AUTHOR

L<Guillaume Aubert|https://metacpan.org/author/AUBERTG>,
C<< <aubertg at cpan.org> >>.


=head1 COPYRIGHT & LICENSE

Copyright 2013-2017 Guillaume Aubert.

This code is free software; you can redistribute it and/or modify it under the
same terms as Perl 5 itself.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the LICENSE file for more details.

=cut

1;
