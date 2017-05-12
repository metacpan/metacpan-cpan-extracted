package App::GitHooks::Plugin::PerlCritic;

use strict;
use warnings;

use base 'App::GitHooks::Plugin';

# External dependencies.
use Perl::Critic;
use Perl::Critic::Git;
use Try::Tiny;

# Internal dependencies.
use App::GitHooks::Constants qw( :PLUGIN_RETURN_CODES );


=head1 NAME

App::GitHooks::Plugin::PerlCritic - Verify that all changes and addition to the Perl files pass PerlCritic checks.


=head1 DESCRIPTION

PerlCritic is a static source code analysis tool. This plugin calls PerlCritic
and verifies that the staged modifications do not trigger any violations.

Note that if you stage half of a file for committing, this plugin will
correctly only check for code violations in the staged half.


=head1 VERSION

Version 1.1.0

=cut

our $VERSION = '1.1.0';

# Tweak the format of the violations reported by PerlCritic.
# Note: the PerlCritic package unfortunately doesn't honor .perlcriticrc,
# unlike the perlcritic executable.
Perl::Critic::Violation::set_format( "%m at line %l column %c.  %e.  (Severity: %s, %p)\n" );


=head1 METHODS

=head2 get_file_pattern()

Return a pattern to filter the files this plugin should analyze.

	my $file_pattern = App::GitHooks::Plugin::PerlCritic->get_file_pattern(
		app => $app,
	);

=cut

sub get_file_pattern
{
	return qr/\.(?:pl|pm|t|cgi)$/x;
}


=head2 get_file_check_description()

Return a description of the check performed on files by the plugin and that
will be displayed to the user, if applicable, along with an indication of the
success or failure of the plugin.

	my $description = App::GitHooks::Plugin::PerlCritic->get_file_check_description();

=cut

sub get_file_check_description
{
	return "The file passes Perl::Critic's review.";
}


=head2 run_pre_commit_file()

Code to execute for each file as part of the pre-commit hook.

  my $success = App::GitHooks::Plugin::PerlCritic->run_pre_commit_file();

=cut

sub run_pre_commit_file
{
	my ( $class, %args ) = @_;
	my $file = delete( $args{'file'} );
	my $git_action = delete( $args{'git_action'} );
	my $app = delete( $args{'app'} );
	my $staged_changes = $app->get_staged_changes();
	my $repository = $app->get_repository();

	# Ignore deleted files.
	return $PLUGIN_RETURN_SKIPPED
		if $git_action eq 'D';

	# Ignore merges, since they correspond mostly to code written by other people.
	return $PLUGIN_RETURN_SKIPPED
		if $staged_changes->is_merge();

	# Ignore revert commits.
	return $PLUGIN_RETURN_SKIPPED
		if $staged_changes->is_revert();

	# Get PerlCritic violations for uncommitted files only.
	my $error = undef;
	my $violations = try
	{
		if ( $git_action eq 'A' )
		{
			my $critic = Perl::Critic->new();
			return [ $critic->critique( $file ) ];
		}
		else
		{
			my $git_critic = Perl::Critic::Git->new(
				file => $repository->work_tree() . '/' . $file,
			);

			return $git_critic->report_violations(
				author => 'not.committed.yet',
			);
		}
	}
	catch
	{
		# Unless PPI dies, we should never get into this catch() part.
		# uncoverable subroutine
		$error = $_;
		return [];
	};

	die "Failed to run PerlCritic: $error.\n"
		if defined( $error );

	die "Violations found:\n" . join( '', map { $_->to_string() } @$violations ) . "\n"
		if scalar( @$violations ) != 0;

	return $PLUGIN_RETURN_PASSED;
}


=head1 BUGS

Please report any bugs or feature requests through the web interface at
L<https://github.com/guillaumeaubert/App-GitHooks-Plugin-PerlCritic/issues/new>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc App::GitHooks::Plugin::PerlCritic


You can also look for information at:

=over

=item * GitHub's request tracker

L<https://github.com/guillaumeaubert/App-GitHooks-Plugin-PerlCritic/issues>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/app-githooks-plugin-perlcritic>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/app-githooks-plugin-perlcritic>

=item * MetaCPAN

L<https://metacpan.org/release/App-GitHooks-Plugin-PerlCritic>

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
