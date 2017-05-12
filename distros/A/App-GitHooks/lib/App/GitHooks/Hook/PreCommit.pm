package App::GitHooks::Hook::PreCommit;

use strict;
use warnings;

# Inherit from the base Hook class.
use base 'App::GitHooks::Hook';

# External dependencies.
use Carp;
use Data::Dumper;
use Data::Validate::Type;
use Path::Tiny qw();

# Internal dependencies.
use App::GitHooks::Constants qw( :HOOK_EXIT_CODES :PLUGIN_RETURN_CODES );


=head1 NAME

App::GitHooks::Hook::PreCommit - Handler for pre-commit hook.


=head1 VERSION

Version 1.9.0

=cut

our $VERSION = '1.9.0';


=head1 METHODS

=head2 run()

Run the hook handler and return an exit status to pass to git.

	my $exit_status = App::GitHooks::Hook::PreCommit->run(
		app => $app,
	);

Arguments:

=over 4

=item * app I<(mandatory)>

An App::GitHooks object.

=back

=cut

sub run
{
	my ( $class, %args ) = @_;
	my $app = delete( $args{'app'} );
	croak 'Unknown argument(s): ' . join( ', ', keys %args )
		if scalar( keys %args ) != 0;

	# Check parameters.
	croak "The 'app' argument is mandatory"
		if !Data::Validate::Type::is_instance( $app, class => 'App::GitHooks' );

	# Remove the file that we use to indicate that pre-commit checks have been
	# run for the set of staged files, in case it exists.
	unlink( '.git/COMMIT-MSG-CHECKS' );

	# If the terminal isn't interactive, we won't have a human available to fix the
	# problems so we just let the commit go as is.
	my $config = $app->get_config();
	my $force_interactive = $config->get( 'testing', 'force_interactive' );
	return $HOOK_EXIT_SUCCESS
		if !$app->get_terminal()->is_interactive() && !$force_interactive;

	# Run the checks on the staged changes.
	my $checks_pass = run_all_tests( $app );

	# If the checks passed, write a file for the prepare-commit-msg hook to know
	# that we've already run the checks and there's no need to do it a second time.
	# This is what allows it to detect when --no-verify was used.
	if ( $checks_pass )
	{
		Path::Tiny::path( '.git', 'COMMIT-MSG-CHECKS' )
			->spew( $checks_pass );
	}

	# Indicate if we should allow continuing to the commit message or not.
	return $checks_pass
		? $HOOK_EXIT_SUCCESS
		: $HOOK_EXIT_FAILURE;
}


=head2 run_all_tests()

Run all the tests available for the pre-commit hook and return whether issues
were detected.

	my $tests_success = run_all_tests( $app );

This is a two step operation:

=over 4

=item 1. We load all the plugins that support "pre-commit", and run them to
analyze the overall pre-commit operation.

=item 2. Each staged file is loaded and we run plugins that support
"pre-commit-file" on each one.

=back

=cut

sub run_all_tests
{
	my ( $app ) = @_;

	# Find all the plugins that support the pre-commit hook.
	my $plugins = $app->get_hook_plugins( 'pre-commit' );

	# Run the plugins.
	my $tests_success = 1;
	my $has_warnings = 0;
	foreach my $plugin ( @$plugins )
	{
		my $check_result = $plugin->run_pre_commit(
			app => $app,
		);

		$tests_success = 0
			if $check_result == $PLUGIN_RETURN_FAILED;

		$has_warnings = 1
			if $check_result == $PLUGIN_RETURN_WARNED;
	}

	# Check the changed files individually with plugins that support
	# "pre-commit-file".
	{
		my ( $file_checks, $file_warnings ) = $app
			->get_staged_changes()
			->verify();
		$tests_success = 0
			if !$file_checks;
		$has_warnings = 1
			if $file_warnings;
	}

	# If warnings were found, notify users.
	if ( $has_warnings )
	{
		# If we have a user, stop and ask if we should continue with the commit.
		# uncoverable branch true
		if ( $app->get_terminal()->is_interactive() )
		{
			print "Some warnings were found. Press <Enter> to continue committing or Ctrl-C to abort the commit.\n";
			my $input = <STDIN>; ## no critic (InputOutput::ProhibitExplicitStdin)
			print "\n";
		}
		# If we don't have a user, just warn and continue.
		else
		{
			print "Some warnings were found, please review.\n";
		}
	}

	return $tests_success;
}


=head1 BUGS

Please report any bugs or feature requests through the web interface at
L<https://github.com/guillaumeaubert/App-GitHooks/issues/new>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc App::GitHooks::Hook::PreCommit


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
