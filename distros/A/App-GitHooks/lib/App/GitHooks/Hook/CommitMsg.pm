package App::GitHooks::Hook::CommitMsg;

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
use App::GitHooks::Constants qw( :HOOK_EXIT_CODES :PLUGIN_RETURN_CODES );
use App::GitHooks::StagedChanges;


=head1 NAME

App::GitHooks::Hook::CommitMsg - Handle the commit-msg hook.


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

	# Reassigns standard input back to the keyboard.
	# Note: this will silently fail in some non-interactive shells where /dev/tty
	# can't be referenced, which is fine since there will be no user typing anyway.
	my $console = $^O eq 'MSWin32'
		? 'CON:'
		: '/dev/tty';
	open( STDIN, '<', $console ); ## no critic (InputOutput::RequireCheckedOpen)

	# If the terminal isn't interactive, we won't have a human available to fix the
	# problems so we just let the commit go as is.
	my $config = $app->get_config();
	my $force_interactive = $config->get( 'testing', 'force_interactive' );
	return $HOOK_EXIT_SUCCESS
		if !$app->get_terminal()->is_interactive() && !$force_interactive;

	# Analyze the commit message and prompt the user to fix it if needed until it
	# passes the checks.
	my $has_errors = 0;
	while ( 1 )
	{
		# Retrieve the commit message.
		my $command_line_arguments = $app->get_command_line_arguments();
		my $commit_message_file = $command_line_arguments->[0];
		my $commit_message = App::GitHooks::CommitMessage->new(
			message => Path::Tiny::path( $commit_message_file )->slurp_utf8() // '',
			app     => $app,
		);

		# If the commit message is empty, don't bother running any checks - git will
		# abort the commit.
		last
			if $commit_message->is_empty();

		# Find all the tests we will need to run.
		my $plugins = $app->get_hook_plugins( $app->get_hook_name() );
		$has_errors = 0;
		foreach my $plugin ( @$plugins )
		{
			my $return_code = $plugin->run_commit_msg(
				app            => $app,
				commit_message => $commit_message,
			);
			$has_errors = 1
				if $return_code == $PLUGIN_RETURN_FAILED;
		}

		# If errors were found, let the user try to fix the commit message,
		# otherwise finish and let git complete.
		if ( $has_errors )
		{
			print "Press <Enter> to edit the commit message or Ctrl-C to abort the commit.\n";
			if ( $app->get_terminal()->is_interactive() )
			{
				my $input = <STDIN>; ## no critic (InputOutput::ProhibitExplicitStdin)

				my $editor = $ENV{'EDITOR'} // 'vim';
				system("$editor $commit_message_file");
				print "\n";
			}
			else
			{
				# $has_errors is set to 1, but we're not in interactive mode so we
				# can't wait for STDIN.
				last;
			}
		}
		else
		{
			# No errors, $has_errors is set to 0, finish.
			last;
		}
	}

	# Success.
	return $has_errors
		? $HOOK_EXIT_FAILURE
		: $HOOK_EXIT_SUCCESS;
}


=head1 BUGS

Please report any bugs or feature requests through the web interface at
L<https://github.com/guillaumeaubert/App-GitHooks/issues/new>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc App::GitHooks::Hook::CommitMsg


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
