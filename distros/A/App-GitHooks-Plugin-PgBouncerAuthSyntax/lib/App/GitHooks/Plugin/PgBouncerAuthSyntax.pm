package App::GitHooks::Plugin::PgBouncerAuthSyntax;

use strict;
use warnings;

use base 'App::GitHooks::Plugin';

# External dependencies.
use Carp;
use File::Slurp qw();

# Internal dependencies.
use App::GitHooks::Constants qw( :PLUGIN_RETURN_CODES );


=head1 NAME

App::GitHooks::Plugin::PgBouncerAuthSyntax - Verify that the syntax of PgBouncer auth files is correct.


=head1 DESCRIPTION

This plugin verifies that staged PgBouncer authentication files have a proper
syntax before allowing the commit to be completed.

See http://pgbouncer.projects.pgfoundry.org/doc/config.html, under the
"Authentication File Format" section, for more information about the required
syntax.


=head1 VERSION

Version 1.1.0

=cut

our $VERSION = '1.1.0';


=head1 CONFIGURATION OPTIONS

This plugin supports the following options in the C<[PgBouncerAuthSyntax]>
section of your C<.githooksrc> file.

	[PgBouncerAuthSyntax]
	file_pattern = /^configs\/pgbouncer\/userlist.txt$/
	comments_setting = disallow


=head2 file_pattern

A regular expression that will be checked against the path of files that are
committed and that indicates a PgBouncer auth file to analyze when it matches.

	file_pattern = /^configs\/pgbouncer\/userlist.txt$/


=head2 comments_setting

As of version 1.5.4, PgBouncer does not allow comments. This will however
change in the next release, thanks to
L<this patch|https://github.com/markokr/pgbouncer-dev/commit/995acda16ce30cde67ab1839387138b7545ff786>.

Configure this setting accordingly based on your PgBouncer version:

=over 4

=item * I<allow_anywhere>

Allow comments anywhere. Use with PgBouncer versions above 1.5.4 (not
included).

	comments_setting = allow_anywhere

=item * I<allow_end_only>

Allow comments at the end of the file only. PgBouncer will stop parsing the
auth file as soon as it encounters an incorrectly formatted line, so you can
technically add comments at the end of the file. This setting will prevent you
from accidentally adding anything but comments once the first comment is seen,
to catch errors that are otherwise tricky to debug.

	comments_setting = allow_end_only

=item * I<disallow>

Don't allow comments at all. The safest setting for PgBouncer versions up to
1.5.4 (included).

	comments_setting = disallow

=back


=head1 METHODS

=head2 get_file_pattern()

Return a pattern to filter the files this plugin should analyze.

	my $file_pattern = App::GitHooks::Plugin::PgBouncerAuthSyntax->get_file_pattern(
		app => $app,
	);

=cut

sub get_file_pattern
{
	my ( $class, %args ) = @_;
	my $app = delete( $args{'app'} );
	my $config = $app->get_config();

	# Retrieve the config value.
	my $regex = $config->get_regex( 'PgBouncerAuthSyntax', 'file_pattern' );
	croak "'file_pattern' is not defined in the  [PgBouncerAuthSyntax] section of your config file"
		if !defined $regex;

	return qr/$regex/;
}


=head2 get_file_check_description()

Return a description of the check performed on files by the plugin and that
will be displayed to the user, if applicable, along with an indication of the
success or failure of the plugin.

	my $description = App::GitHooks::Plugin::PgBouncerAuthSyntax->get_file_check_description();

=cut

sub get_file_check_description
{
	return 'The PgBouncer syntax is correct';
}


=head2 run_pre_commit_file()

Code to execute for each file as part of the pre-commit hook.

  my $success = App::GitHooks::Plugin::PgBouncerAuthSyntax->run_pre_commit_file();

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

	# Determine which setting to use for comments.
	my $comments_setting = $config->get( 'PgBouncerAuthSyntax', 'comments_setting' );
	croak '"comments_setting" needs to be defined in the [PgBouncerAuthSyntax] section of your .githooksrc file'
		if !defined( $comments_setting ) || ( $comments_setting eq '' );
	croak 'The value of "comments_setting" in the [PgBouncerAuthSyntax] section of your .githooksrc file is not valid'
		if $comments_setting !~ /^(?:allow_anywhere|allow_end_only|disallow)$/x;

	# Retrieve lines.
	my @lines = File::Slurp::read_file( $repository->work_tree() . '/' . $file );

	# Find the incorrectly formatted lines.
	my @issues = ();
	my $comments_detected = 0;
	for ( my $i = 0; $i < scalar( @lines ); $i++ )
	{
		my $line = $lines[ $i ];

		# Skip blank lines.
		next
			if !defined( $line ) || ( $line eq '' );

		# Handle comments.
		if ( substr( $line, 0, 1 ) eq ';' )
		{
			$comments_detected = 1;

			# If we don't allow comments, note the error before moving on to the next
			# line.
			if ( $comments_setting eq 'disallow' )
			{
				push(
					@issues,
					{
						line_number => $i,
						line        => $line,
					}
				);
			}

			next;
		}
		if ( $comments_detected && ( $comments_setting eq 'allow_end_only' ) )
		{
			# This line is not a comment, but comment lines have already been seen
			# and we only allow comments at the end of the file.
			push(
				@issues,
				{
					line_number => $i,
					line        => $line,
				}
			);
			next;
		}

		# Skip lines with the correct username/password specification.
		next
			if $line =~ /
					^
					"[^"]*"   # Username.
					\         # Space.
					"[^"]*"   # Password.
					(?:\ .*)? # Remainder of the line, no specific format required except
					          # for a space if anything follows.
					$
				/x;

		push(
			@issues,
			{
				line_number => $i,
				line        => $line,
			}
		);
	}

	die "Incorrectly formatted lines:\n" . join( '', map { "Line $_->{'line_number'}: $_->{'line'}" } @issues ) . "\n"
		if scalar( @issues ) != 0;

	return $PLUGIN_RETURN_PASSED;
}


=head1 BUGS

Please report any bugs or feature requests through the web interface at
L<https://github.com/guillaumeaubert/App-GitHooks-Plugin-PgBouncerAuthSyntax/issues/new>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc App::GitHooks::Plugin::PgBouncerAuthSyntax


You can also look for information at:

=over

=item * GitHub's request tracker

L<https://github.com/guillaumeaubert/App-GitHooks-Plugin-PgBouncerAuthSyntax/issues>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/app-githooks-plugin-pgbouncerauthsyntax>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/app-githooks-plugin-pgbouncerauthsyntax>

=item * MetaCPAN

L<https://metacpan.org/release/App-GitHooks-Plugin-PgBouncerAuthSyntax>

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
