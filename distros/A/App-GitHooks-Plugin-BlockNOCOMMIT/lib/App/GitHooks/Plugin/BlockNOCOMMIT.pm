package App::GitHooks::Plugin::BlockNOCOMMIT;

use strict;
use warnings;

use base 'App::GitHooks::Plugin';


# External dependencies.
use Carp;
use Data::Validate::Type;
use File::Slurp ();

# Internal dependencies.
use App::GitHooks::Constants qw( :PLUGIN_RETURN_CODES );


=head1 NAME

App::GitHooks::Plugin::BlockNOCOMMIT - Prevent committing code with #NOCOMMIT mentions.


=head1 DESCRIPTION

Sometimes you want to experiment with code, but you want to make sure that test
code doesn't get committed by accident.

This plugin allows you to use C<#NOCOMMIT> to indicate such code blocks, and
will prevent you from committing those blocks.

For example:

	# This is a test that will not work once deployed.
	# NOCOMMIT
	...

Note that the following variations on the tag are correctly picked up:

=over 4

=item * C<#NOCOMMIT>

=item * C<# NOCOMMIT>

=item * C<# NO COMMIT>

=back


=head1 VERSION

Version 1.1.1

=cut

our $VERSION = '1.1.1';


=head1 METHODS

=head2 get_file_pattern()

Return a pattern to filter the files this plugin should analyze.

	my $file_pattern = App::GitHooks::Plugin::BlockNOCOMMIT->get_file_pattern(
		app => $app,
	);

=cut

sub get_file_pattern
{
	# Check all files.
	return qr//;
}


=head2 get_file_check_description()

Return a description of the check performed on files by the plugin and that
will be displayed to the user, if applicable, along with an indication of the
success or failure of the plugin.

	my $description = App::GitHooks::Plugin::BlockNOCOMMIT->get_file_check_description();

=cut

sub get_file_check_description
{
	return 'The file has no #NOCOMMIT tags.';
}


=head2 run_pre_commit_file()

Code to execute for each file as part of the pre-commit hook.

	my $success = App::GitHooks::Plugin::BlockNOCOMMIT->run_pre_commit_file();

=cut

sub run_pre_commit_file
{
	my ( $class, %args ) = @_;
	my $app = delete( $args{'app'} );
	my $file = delete( $args{'file'} );
	my $git_action = delete( $args{'git_action'} );
	croak 'Unknown argument(s): ' . join( ', ', keys %args )
		if scalar( keys %args ) != 0;

	# Check parameters.
	croak "The 'app' argument is mandatory"
		if !Data::Validate::Type::is_instance( $app, class => 'App::GitHooks' );
	croak "The 'file' argument is mandatory"
		if !defined( $file );
	croak "The 'git_action' argument is mandatory"
		if !defined( $git_action );

	# Ignore deleted files.
	return $PLUGIN_RETURN_SKIPPED
		if $git_action eq 'D';

	# Ignore merges, since they correspond mostly to code written by other people.
	my $staged_changes = $app->get_staged_changes();
	return $PLUGIN_RETURN_SKIPPED
		if $staged_changes->is_merge();

	# Ignore revert commits.
	return $PLUGIN_RETURN_SKIPPED
			if $staged_changes->is_revert();

	# Determine what lines were written by the current user.
	my @review_lines = ();
	if ( $git_action eq 'A' )
	{
		# "git blame" fails on new files, so we need to add the entire file
		# separately.
		my @lines = File::Slurp::read_file( $file );
		foreach my $i ( 0 .. scalar( @lines ) - 1 ) {
			chomp( $lines[$i] );
			push(
				@review_lines,
				{
					line_number => $i,
					code        => $lines[$i],
				}
			);
		}
	}
	else
	{
		# Find uncommitted lines only.
		my $repository = $app->get_repository();
		my $blame_lines = $repository->blame(
			$file,
			use_cache => 1,
		);

		foreach my $blame_line ( @$blame_lines )
		{
			my $commit_attributes = $blame_line->get_commit_attributes();
			next unless $commit_attributes->{'author-mail'} eq 'not.committed.yet';
			push(
				@review_lines,
				{
					line_number => $blame_line->get_line_number(),
					code        => $blame_line->get_line(),
				}
			);
		}
	}

	# Inspect uncommitted lines for NOCOMMIT mentions.
	my @violations = ();
	foreach my $line ( @review_lines )
	{
		my $code = $line->{'code'};
		next if $code !~ /
			(?:\/\/|\#)      # Support Perl and Javascript comments.
			.*               # Support NOCOMMIT anywhere in the comment, not just at the beginning.
			\bNO\s*COMMIT\b  # Support NOCOMMIT and NO COMMIT.
		/ix;

		my $bad_line = $code;
		$bad_line =~ s/\b(NO\s*COMMIT)\b/$app->color('red', $1)/iegs;
		push(
			@violations,
			sprintf( "line #%d:   %s\n", $line->{'line_number'}, $bad_line )
		);
	}

	die "#NOCOMMIT tags found:\n" . join( '', @violations ) . "\n"
			if scalar( @violations ) != 0;

	return $PLUGIN_RETURN_PASSED;
}


=head1 BUGS

Please report any bugs or feature requests through the web interface at
L<https://github.com/guillaumeaubert/App-GitHooks-Plugin-BlockNoCommit/issues/new>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc App::GitHooks::Plugin::BlockNOCOMMIT


You can also look for information at:

=over

=item * GitHub's request tracker

L<https://github.com/guillaumeaubert/App-GitHooks-Plugin-BlockNoCommit/issues>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/app-githooks-plugin-blocknocommit>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/app-githooks-plugin-blocknocommit>

=item * MetaCPAN

L<https://metacpan.org/release/App-GitHooks-Plugin-BlockNoCommit>

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
