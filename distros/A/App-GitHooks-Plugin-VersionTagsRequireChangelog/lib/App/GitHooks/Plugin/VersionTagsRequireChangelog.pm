package App::GitHooks::Plugin::VersionTagsRequireChangelog;

use strict;
use warnings;

use base 'App::GitHooks::Plugin';

# External dependencies.
use CPAN::Changes;
use Log::Any qw($log);
use Try::Tiny;

# Internal dependencies.
use App::GitHooks::Constants qw( :PLUGIN_RETURN_CODES );

# Uncomment to see debug information.
#use Log::Any::Adapter ('Stderr');


=head1 NAME

App::GitHooks::Plugin::VersionTagsRequireChangelog - Require git version tags to have a matching changelog entry.


=head1 DESCRIPTION

This is a companion plugin for L<App::GitHooks::Plugin::NotifyReleasesToSlack>.
C<NotifyReleasesToSlack> simply skips git version tags without a matching entry
in the changelog file, and this plugin allows you to force git version tags to
have a matching entry in the changelog file.

For example, you cannot do this:

	git tag v1.0.0
	git push origin v1.0.0

Unless your changelog file has a release entry for C<v1.0.0>.


=head1 VERSION

Version 1.1.0

=cut

our $VERSION = '1.1.0';


=head1 CONFIGURATION OPTIONS

This plugin supports the following options in the
C<[VersionTagsRequireChangelog]> section of your C<.githooksrc> file.

	[VersionTagsRequireChangelog]
	changelog_path = Changes


=head2 changelog_path

The path to the changelog file, relative to the root of the repository.

For example, if the changelog file is named C<Changes> and lives at the root of
your repository:

	changelog_path = Changes


=head1 METHODS

=head2 run_pre_push()

Code to execute as part of the pre-push hook.

	my $plugin_return_code = App::GitHooks::Plugin::VersionTagsRequireChangelog->run_pre_push(
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

	$log->info( 'Entering VersionTagsRequireChangelog.' );

	my $config = $app->get_config();
	my $repository = $app->get_repository();

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

	# Find tags without release notes.
	my @missing_changelog_tags =
		grep { !defined( $releases->{ $_ } ) }
		@tags;

	if ( scalar( @missing_changelog_tags ) != 0 )
	{
		die sprintf(
			'You are trying to push the following %s, but %s missing from the changelog: %s.',
			scalar( @missing_changelog_tags ) == 1 ? 'tag' : 'tags',
			scalar( @missing_changelog_tags ) == 1 ? 'it is' : 'they are',
			join( ', ', @missing_changelog_tags ),
		) . "\n";
	}

	return $PLUGIN_RETURN_PASSED;
}


=head1 FUNCTIONS

=head2 get_pushed_tags()

Retrieve a list of the tags being pushed with C<git push>.

	my $tags = App::GitHooks::Plugin::VersionTagsRequireChangelog::get_pushed_tags(
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
	my $version_tag_regex = $config->get_regex( 'VersionTagsRequireChangelog', 'version_tag_regex' )
		// '(v\d+\.\d+\.\d+)';
	$log->infof( "Using git tag regex '%s'.", $version_tag_regex );

	# Analyze each reference being pushed.
	my $tags = {};
	foreach my $line ( @$stdin )
	{
		chomp( $line );
		$log->debugf( 'Parse STDIN line >%s<.', $line );

		# Extract the tag information.
		my ( $tag ) = ( $line =~ /^refs\/tags\/$version_tag_regex\b/x );
		next if !defined( $tag );
		$log->infof( "Found tag '%s'.", $tag );
		$tags->{ $tag } = 1;
	}

	return keys %$tags;
}


=head2 get_changelog_releases()

Retrieve a hashref of all the releases in the changelog file.

	my $releases = App::GitHooks::Plugin::VersionTagsRequireChangelog::get_changelog_releases(
		$app,
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
	my $changelog_path = $config->get( 'VersionTagsRequireChangelog', 'changelog_path' );
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
	$log->infof( "Found %s release(s) in the changelog file.", scalar( keys %$releases ) );

	return $releases;
}


=head1 BUGS

Please report any bugs or feature requests through the web interface at
L<https://github.com/guillaumeaubert/App-GitHooks-Plugin-VersionTagsRequireChangelog/issues/new>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc App::GitHooks::Plugin::VersionTagsRequireChangelog


You can also look for information at:

=over

=item * GitHub's request tracker

L<https://github.com/guillaumeaubert/App-GitHooks-Plugin-VersionTagsRequireChangelog/issues>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/app-githooks-plugin-versiontagsrequirechangelog>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/app-githooks-plugin-versiontagsrequirechangelog>

=item * MetaCPAN

L<https://metacpan.org/release/App-GitHooks-Plugin-VersionTagsRequireChangelog>

=back


=head1 AUTHOR

L<Guillaume Aubert|https://metacpan.org/author/AUBERTG>,
C<< <aubertg at cpan.org> >>.


=head1 COPYRIGHT & LICENSE

Copyright 2015-2017 Guillaume Aubert.

This code is free software; you can redistribute it and/or modify it under the
same terms as Perl 5 itself.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the LICENSE file for more details.

=cut

1;
