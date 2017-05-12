package App::GitHooks::Hook::PrepareCommitMsg;

use strict;
use warnings;

# Inherit from the base Hook class.
use base 'App::GitHooks::Hook';

# External dependencies.
use Carp;
use Data::Dumper;
use Path::Tiny qw();

# Internal dependencies.
use App::GitHooks::CommitMessage;
use App::GitHooks::Constants qw( :PLUGIN_RETURN_CODES :HOOK_EXIT_CODES );


=head1 NAME

App::GitHooks::Hook::CommitMsg - Handler for commit-msg hook.


=head1 VERSION

Version 1.9.0

=cut

our $VERSION = '1.9.0';


=head1 METHODS

=head2 run()

Run the hook handler and return an exit status to pass to git.

	my $exit_status = App::GitHooks::Hook::CommitMsg->run(
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

	# Retrieve the commit message.
	my $command_line_arguments = $app->get_command_line_arguments();
	my $commit_message_file = $command_line_arguments->[0];
	my $commit_message = App::GitHooks::CommitMessage->new(
		message => Path::Tiny::path( $commit_message_file )->slurp_utf8() // '',
		app     => $app,
	);

	# Find and run all the plugins that support the prepare-commit-msg hook.
	my $tests_success = 1;
	my $plugins = $app->get_hook_plugins( 'prepare-commit-msg' );
	foreach my $plugin ( @$plugins )
	{
		my $check_result = $plugin->run_prepare_commit_msg(
			app            => $app,
			commit_message => $commit_message,
		);
		$tests_success = 0
			if $check_result == $PLUGIN_RETURN_FAILED;
	}

	# If the commit message was modified above, we need to overwrite the file.
	if ( $commit_message->has_changed() )
	{
		my $terminal = $app->get_terminal();
		my $message = $commit_message->get_message();
		my $file = Path::Tiny::path( $commit_message_file );
		$terminal->is_utf8()
			? $file->spew_utf8( $message )
			: $file->spew( $message );
	}

	# .git/COMMIT-MSG-CHECKS is a file we use to track if the pre-commit hook has
	# run, as opposed to being skipped with --no-verify. Since pre-commit can be
	# skipped, but prepare-commit-msg cannot, plugins can use the presence of
	# that file to determine if some optional processing should be performed in
	# the prepare-commit-msg phase. For example, you may want to add a warning
	# indicating that --no-verify was used. Note however that the githooks man
	# page says "it should not be used as replacement for pre-commit hook".
	#
	# And since we're done with prepare-commit-msg checks now, we can safely
	# remove the file.
	unlink( '.git/COMMIT-MSG-CHECKS' );

	return $tests_success
		? $HOOK_EXIT_SUCCESS
		: $HOOK_EXIT_FAILURE;
}


=head1 BUGS

Please report any bugs or feature requests through the web interface at
L<https://github.com/guillaumeaubert/App-GitHooks/issues/new>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc App::GitHooks::Hook::PrepareCommitMsg


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
