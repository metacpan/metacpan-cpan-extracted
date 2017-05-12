package App::GitHooks::Plugin::ValidateChangelogFormat;

use strict;
use warnings;

use base 'App::GitHooks::Plugin';

# Internal dependencies.
use App::GitHooks::Constants qw( :PLUGIN_RETURN_CODES );

# External dependencies.
use CPAN::Changes;
use Try::Tiny;
use version qw();


=head1 NAME

App::GitHooks::Plugin::ValidateChangelogFormat - Validate the format of changelog files.


=head1 DESCRIPTION

This plugin verifies that the changes log conforms to the specifications
outlined in C<CPAN::Changes::Spec>.


=head1 VERSION

Version 1.1.0

=cut

our $VERSION = '1.1.0';


=head1 CONFIGURATION OPTIONS

This plugin supports the following options in the C<[ValidateChangelogFormat]>
section of your C<.githooksrc> file.

	[ValidateChangelogFormat]
	version_format_regex = /^v\d+\.\d+\.\d+$/
	date_format_regex = /^\d{4}-\d{2}-\d{2}$/


=head2 version_format_regex

A regular expression that will be checked against the version number for each
release listed in the change log.

	version_format_regex = /^v\d+\.\d+\.\d+$/

By default, this plugin allows the versioning schemes described in
L<CPAN::Meta::Spec/Version-Formats>.


=head2 date_format_regex

A regular expression that will be checked against the date for each release
listed in the change log.

	date_format_regex = /^\d{4}-\d{2}-\d{2}$/

By default, this plugin allows the date formats listed in
L<CPAN::Changes::Spec/Date>.


=head1 METHODS

=head2 get_file_pattern()

Return a pattern to filter the files this plugin should analyze.

	my $file_pattern = App::GitHooks::Plugin::ValidateChangelogFormat->get_file_pattern(
		app => $app,
	);

By default, this catches files named changes or changelog, with an optional
extension of .md or .pod. The name of the files is not case sensitive.

=cut

sub get_file_pattern
{
	return qr/^(?:changes|changelog)(?:\.(?:md|pod))?$/ix;
}


=head2 get_file_check_description()

Return a description of the check performed on files by the plugin and that
will be displayed to the user, if applicable, along with an indication of the
success or failure of the plugin.

	my $description = App::GitHooks::Plugin::ValidateChangelogFormat->get_file_check_description();

=cut

sub get_file_check_description
{
	return 'The changelog format matches CPAN::Changes::Spec.';
}

=head2 run_pre_commit_file()

Code to execute for each file as part of the pre-commit hook.

	my $success = App::GitHooks::Plugin::ValidateChangelogFormat->run_pre_commit_file();

The code in this subroutine is mostly adapted from L<Test::CPAN::Changes>.

=cut

sub run_pre_commit_file
{
	my ( $class, %args ) = @_;
	my $file = delete( $args{'file'} );
	my $git_action = delete( $args{'git_action'} );
	my $app = delete( $args{'app'} );
	my $repository = $app->get_repository();
	my $config = $app->get_config();

	# Ignore deleted files.
	return $PLUGIN_RETURN_SKIPPED
		if $git_action eq 'D';

	# Determine the required date format.
	my $date_format_regex = $config->get_regex( 'ValidateChangelogFormat', 'date_format_regex' );
	$date_format_regex = defined( $date_format_regex )
		? qr/^$date_format_regex$/
		: qr/^(?:${CPAN::Changes::W3CDTF_REGEX}|${CPAN::Changes::UNKNOWN_VALS})$/x;

	# Determine the required version format.
	my $version_format_regex = $config->get_regex( 'ValidateChangelogFormat', 'version_format_regex' );

	# Parse the changelog file.
	my $changes =
	try
	{
		return CPAN::Changes->load( $repository->work_tree() . '/' . $file );
	}
	catch
	{
		die "Unable to parse the change log\n";
	};

	# Verify that the changelog contains releases.
	my @releases = $changes->releases();
	die "The change log does not contain any releases\n"
		if scalar( @releases ) == 0;

	my @errors = ();
	my $count = 0;
	foreach my $release ( @releases )
	{
		# Prefix to identify which release has issues in the error messages.
		$count++;
		my $error_prefix = sprintf(
			"Release %s/%s",
			$count,
			scalar( @releases ),
		);

		# Validate the release date.
		try
		{
			my $date = $release->date();

			die "the release date is missing.\n"
				if !defined( $date ) || ( $date eq '' );

			die "date '$date' is not in the recommended format.\n"
				if $date !~ $date_format_regex;
		}
		catch
		{
			push( @errors, "$error_prefix: $_" );
		};

		# Validate the release version.
		try
		{
			my $version = $release->version();

			die "the version number is missing.\n"
				if $version eq '';

			if ( defined( $version_format_regex ) )
			{
				die "version '$version' is not a valid version number.\n"
					if $version !~ qr/^$version_format_regex$/x;
			}
			else
			{
				die "version '$version' is not a valid version number.\n"
					if !version::is_lax($version);
			}
		}
		catch
		{
			push( @errors, "$error_prefix: $_" );
		};

		# Verify that a list of changes is present.
		try
		{
			my $description = $release->changes();

			die "the release does not contain a description of changes.\n"
				if scalar( keys %$description ) == 0;
		}
		catch
		{
			push( @errors, "$error_prefix: $_" );
		};
	}

	# Raise an exception with all the errors found, if any.
	die join( '', @errors ) . "\n"
		if scalar( @errors ) != 0;

	return $PLUGIN_RETURN_PASSED;
}


=head1 SEE ALSO

=over 4

=item * L<Test::CPAN::Changes>

=item * L<CPAN::Changes::Spec>

=item * L<CPAN::Changes>

=back


=head1 BUGS

Please report any bugs or feature requests through the web interface at
L<https://github.com/guillaumeaubert/App-GitHooks-Plugin-ValidateChangelogFormat/issues/new>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc App::GitHooks::Plugin::ValidateChangelogFormat


You can also look for information at:

=over

=item * GitHub's request tracker

L<https://github.com/guillaumeaubert/App-GitHooks-Plugin-ValidateChangelogFormat/issues>

=item * AnnoCPAN: Annotated CPAN documentation

l<http://annocpan.org/dist/app-githooks-plugin-validatechangelogformat>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/app-githooks-plugin-validatechangelogformat>

=item * MetaCPAN

L<https://metacpan.org/release/App-GitHooks-Plugin-ValidateChangelogFormat>

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
