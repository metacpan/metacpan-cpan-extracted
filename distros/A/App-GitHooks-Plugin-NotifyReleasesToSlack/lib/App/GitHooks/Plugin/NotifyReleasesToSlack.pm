package App::GitHooks::Plugin::NotifyReleasesToSlack;

use strict;
use warnings;

use feature 'state';

use base 'App::GitHooks::Plugin';

# External dependencies.
use CPAN::Changes;
use Data::Dumper;
use JSON qw();
use LWP::UserAgent;
use Log::Any qw($log);
use Try::Tiny;

# Internal dependencies.
use App::GitHooks::Constants qw( :PLUGIN_RETURN_CODES );

# Uncomment to see debug information.
#use Log::Any::Adapter ('Stderr');


=head1 NAME

App::GitHooks::Plugin::NotifyReleasesToSlack - Notify Slack channels of new releases pushed from a repository.


=head1 DESCRIPTION

If you maintain a changelog file, and tag your release commits, you can use
this plugin to send the release notes to Slack channels.

Here is a practical scenario:

=over 4

=item 1.

Install C<App::GitHooks::Plugin::NotifyReleasesToSlack>.

=item 2.

Set up an incoming webhook in Slack. This should give you a URL to post
messages to, with a format similar to
C<https://hooks.slack.com/services/.../.../...>.

=item 3.

Configure the plugin in your C<.githooksrc> file:

	[NotifyReleasesToSlack]
	slack_post_url = ...
	slack_channels = #releases, #test
	changelog_path = Changes

=item 4.

Add release notes in your changelog file:

	v1.0.0  2015-04-12
	        - Added first feature.
	        - Added second feature.

=item 5.

Commit your release notes:

	git commit Changelog -m 'Release version 1.0.0.'

=item 6.

Tag your release:

	git tag v1.0.0
	git push origin v1.0.0

=item 7.

Watch the notification appear in the corresponding Slack channel(s):

	release-notes BOT: @channel - Release v1.0.0 of test_repo:
	- Added first feature.
	- Added second feature.

=back

=head1 VERSION

Version 1.1.1

=cut

our $VERSION = '1.1.1';


=head1 CONFIGURATION OPTIONS

This plugin supports the following options in the C<[NotifyReleasesToSlack]>
section of your C<.githooksrc> file.

	[NotifyReleasesToSlack]
	slack_post_url = https://hooks.slack.com/services/.../.../...
	slack_channels = #releases, #test
	changelog_path = Changes
	notify_everyone = true


=head2 slack_post_url

After you set up a new incoming webhook in Slack, check under "Integration
settings" for the following information: "Webhook URL", "Send your JSON
payloads to this URL". This is the URL you need to set as the value for the
C<slack_post_url> config option.

	slack_post_url = https://hooks.slack.com/services/.../.../...


=head2 slack_channels

The comma-separated list of channels to send release notifications to.

	slack_channels = #releases, #test

Don't forget to prefix the channel names with '#'. It may still work without
it, but some keywords are reserved by Slack and you may see inconsistent
behaviors between channels.


=head2 changelog_path

The path to the changelog file, relative to the root of the repository.

For example, if the changelog file is named C<Changes> and lives at the root of
your repository:

	changelog_path = Changes


=head2 notify_everyone

Whether @everyone in the Slack channel(s) should be notified or not. C<true> by
default, but can be set to C<false> to simply announce releases in the channel
without notification.

	# Notify @everyone in the channel.
	notify_everyone = true

	# Just announce in the channel.
	notify_everyone = false


=head1 METHODS

=head2 run_pre_push()

Code to execute as part of the pre-push hook.

  my $plugin_return_code = App::GitHooks::Plugin::NotifyReleasesToSlack->run_pre_push(
		app   => $app,
		stdin => $stdin,
	);

Arguments:

=over 4

=item * $app I<(mandatory)>

An C<App::GitHooks> object.

=item * $stdin I<(mandatory)>

The content provided by git on stdin, corresponding to a list of references
being pushed.

=back

=cut

sub run_pre_push
{
	my ( $class, %args ) = @_;
	my $app = delete( $args{'app'} );
	my $stdin = delete( $args{'stdin'} );
	my $config = $app->get_config();

	$log->info( 'Entering NotifyReleasesToSlack.' );

	# Verify that the mandatory config options are present.
	my $config_return = verify_config( $config );
	return $config_return
		if defined( $config_return );

	# Check if we are pushing any tags.
	my @tags = get_pushed_tags( $app, $stdin );
	$log->infof( "Found %s tag(s) to push.", scalar( @tags ) );
	if ( scalar( @tags ) == 0 )
	{
		$log->info( "No tags were found in the list of references to push." );
		return $PLUGIN_RETURN_SKIPPED;
	}

	# Get the list of releases in the changelog.
	my $releases = get_changelog_releases( $app );
	$log->infof( "Found %s release(s) in the changelog file.", scalar( keys %$releases ) );

	# Determine the name of the repository.
	my $remote_name = get_remote_name( $app );
	$log->infof( "The repository's remote name is %s.", $remote_name );

	# Determine if we should just announce releases in a normal message, or
	# notify everyone in each channel.
	my $notify_everyone = $config->get( 'NotifyReleasesToSlack', 'notify_everyone' );
	$notify_everyone = defined( $notify_everyone ) && ( $notify_everyone eq 'false' )
		? 0
		: 1;

	# Analyze tags.
	foreach my $tag ( @tags )
	{
		# Check if there's an entry in the changelog.
		my $release = $releases->{ $tag };
		if ( !defined( $release ) )
		{
			$log->infof( "No release found in the changelog for tag '%s'.", $tag );
			next;
		}
		$log->infof( "Found release notes for %s.", $tag );

		# Serialize release notes.
		my $serialized_notes = join(
			"\n",
			map { $_->serialize() } $release->group_values()
		);

		# Notify Slack.
		notify_slack(
			$app,
			sprintf(
				"*%sRelease %s of %s:*\n%s",
				$notify_everyone
					? '<!everyone> - '
					: '',
				$tag,
				$remote_name,
				$serialized_notes,
			),
		);
	}

	return $PLUGIN_RETURN_PASSED;
}


=head1 FUNCTIONS

=head2 verify_config()

Verify that the mandatory options are defined in the current githooksrc config.

	my $plugin_return_code = App::GitHooks::Plugin::NotifyReleasesToSlack::verify_config(
		$config
	);

Arguments:

=over 4

=item * $config I<(mandatory)>

An C<App::GitHooks::Config> object.

=back

=cut

sub verify_config
{
	my ( $config ) = @_;

	# Check if a Slack post url is defined in the config.
	my $slack_post_url = $config->get( 'NotifyReleasesToSlack', 'slack_post_url' );
	if ( !defined( $slack_post_url ) )
	{
		$log->info('No Slack post URL defined in the [NotifyReleasesToSlack] section, skipping plugin.');
		return $PLUGIN_RETURN_SKIPPED;
	}

	# Check if Slack channels are defined in the config.
	my $slack_channels = $config->get( 'NotifyReleasesToSlack', 'slack_channels' );
	if ( !defined( $slack_channels ) )
	{
		$log->info('No Slack channels to post to defined in the [NotifyReleasesToSlack] section, skipping plugin.');
		return $PLUGIN_RETURN_SKIPPED;
	}

	# Check if a changelog is defined in the config.
	my $changelog_path = $config->get( 'NotifyReleasesToSlack', 'changelog_path' );
	if ( !defined( $changelog_path ) )
	{
		$log->info( "'changelog_path' is not defined in the [NotifyReleasesToSlack] section of your .githooksrc config." );
		return $PLUGIN_RETURN_SKIPPED;
	}

	# If notify_everyone is set, make sure the value is valid.
	my $notify_everyone = $config->get( 'NotifyReleasesToSlack', 'notify_everyone' );
	if ( defined( $notify_everyone ) && ( $notify_everyone !~ /(?:true|false)/ ) )
	{
		my $error = "'notify_everyone' is defined in [NotifyReleasesToSlack] but the value is not valid";
		$log->error( "$error." );
		die "$error\n";
	}

	return undef;
}


=head2 get_remote_name()

Get the name of the repository.

	my $remote_name = App::GitHooks::Plugin::NotifyReleasesToSlack::get_remote_name(
		$app
	);

Arguments:

=over 4

=item * $app I<(mandatory)>

An C<App::GitHooks> object.

=back

=cut

sub get_remote_name
{
	my ( $app ) = @_;
	my $repository = $app->get_repository();

	# Retrieve the remote path.
	$log->info('run git');
	my $remote = $repository->run( qw( config --get remote.origin.url ) ) // '';
	$log->info('run git');

	# Extract the remote name.
	my ( $remote_name ) = ( $remote =~ /\/(.*?)\.git$/i );
	$remote_name //= '(no remote found)';
	$log->info('run git');

	return $remote_name;
}


=head2 notify_slack()

Display a notification in the Slack channels defined in the config file.

	App::GitHooks::Plugin::NotifyReleasesToSlack::notify_slack(
		$app,
		$message,
	);

Arguments:

=over 4

=item * $app I<(mandatory)>

An C<App::GitHooks> object.

=item * $message I<(mandatory)>

The message to display in Slack channels.

=back

=cut

sub notify_slack
{
	my ( $app, $message ) = @_;
	my $config = $app->get_config();

	# Get the list of channels to notify
	state $slack_channels =
	[
		split(
			/\s*,\s*/,
			$config->get( 'NotifyReleasesToSlack', 'slack_channels' )
		)
	];

	# Notify Slack channels.
	foreach my $channel ( @$slack_channels )
	{
		$log->infof( 'Notifying Slack channel %s: %s', $channel, $message );

		# Prepare payload for the request.
		my $request_payload =
			JSON::encode_json(
				{
					text     => $message,
					channel  => $channel,
				}
			);

		# Prepare request.
		my $request = HTTP::Request->new(
			POST => $config->get( 'NotifyReleasesToSlack', 'slack_post_url' ),
		);
		$request->content( $request_payload );

		# Send request to Slack.
		my $user_agent = LWP::UserAgent->new();
		my $response = $user_agent->request( $request );

		# If the connection is down, or Slack is down, warn the user.
		if ( !$response->is_success() )
		{
			my $error = sprintf(
				"Failed to notify channel '%s' with message '%s'.\n>>> %s %s.",
				$channel,
				$message,
				$response->code(),
				$response->message(),
			);

			# Notify any logging systems.
			$log->error( $error );

			# Notify the user who is pushing tags.
			print STDERR "$error\n";
		}
	}

	return;
}


=head2 get_changelog_releases()

Retrieve a hashref of all the releases in the changelog file.

	my $releases = App::GitHooks::Plugin::NotifyReleasesToSlack::get_changelog_releases(
		$app
	);

Arguments:

=over 4

=item * $app I<(mandatory)>

An C<App::GitHooks> object.

=back

=cut

sub get_changelog_releases
{
	my ( $app ) = @_;
	my $repository = $app->get_repository();
	my $config = $app->get_config();

	# Make sure the changelog file exists.
	my $changelog_path = $config->get( 'NotifyReleasesToSlack', 'changelog_path' );
	$changelog_path = $repository->work_tree() . '/' . $changelog_path;
	die "The changelog '$changelog_path' specified in your .githooksrc config does not exist in the repository\n"
		if ! -e $changelog_path;
	$log->infof( "Using changelog '%s'.", $changelog_path );

	# Read the changelog.
	my $changes =
	try
	{
		return CPAN::Changes->load( $changelog_path );
	}
	catch
	{
		$log->error( "Unable to parse the change log" );
		die "Unable to parse the change log\n";
	};
	$log->info( 'Successfully parsed the change log file.' );

	# Organize the releases into a hash for easy lookup.
	my $releases =
	{
		map { $_->version() => $_ }
		$changes->releases()
	};

	return $releases;
}


=head2 get_pushed_tags()

Retrieve a list of the tags being pushed with C<git push>.

	my @tags = App::GitHooks::Plugin::NotifyReleasesToSlack::get_pushed_tags(
		$app,
		$stdin,
	);

Arguments:

=over 4

=item * $app I<(mandatory)>

An C<App::GitHooks> object.

=item * $stdin I<(mandatory)>

The content provided by git on stdin, corresponding to a list of references
being pushed.

=back

=cut

sub get_pushed_tags
{
	my ( $app, $stdin ) = @_;
	my $config = $app->get_config();

	# Tag pattern.
	my $git_tag_regex = $config->get_regex( 'NotifyReleasesToSlack', 'git_tag_regex' )
		// '(v\d+\.\d+\.\d+)';
	$log->infof( "Using git tag regex '%s'.", $git_tag_regex );

	# Analyze each reference being pushed.
	my $tags = {};
	foreach my $line ( @$stdin )
	{
		chomp( $line );
		$log->debugf( 'Parse STDIN line >%s<.', $line );

		# Extract the tag information.
		my ( $tag ) = ( $line =~ /^refs\/tags\/$git_tag_regex\b/x );
		next if !defined( $tag );
		$log->infof( "Found tag '%s'.", $tag );
		$tags->{ $tag } = 1;
	}

	return keys %$tags;
}


=head1 BUGS

Please report any bugs or feature requests through the web interface at
L<https://github.com/guillaumeaubert/App-GitHooks-Plugin-NotifyReleasesToSlack/issues/new>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc App::GitHooks::Plugin::NotifyReleasesToSlack


You can also look for information at:

=over

=item * GitHub's request tracker

L<https://github.com/guillaumeaubert/App-GitHooks-Plugin-NotifyReleasesToSlack/issues>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/app-githooks-plugin-notifyreleasestoslack>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/app-githooks-plugin-notifyreleasestoslack>

=item * MetaCPAN

L<https://metacpan.org/release/App-GitHooks-Plugin-NotifyReleasesToSlack>

=back


=head1 AUTHOR

L<Guillaume Aubert|https://metacpan.org/author/AUBERTG>,
C<< <aubertg at cpan.org> >>.


=head1 COPYRIGHT & LICENSE

Copyright 2013-2016 Guillaume Aubert.

This code is free software; you can redistribute it and/or modify it under the
same terms as Perl 5 itself.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the LICENSE file for more details.

=cut

1;
