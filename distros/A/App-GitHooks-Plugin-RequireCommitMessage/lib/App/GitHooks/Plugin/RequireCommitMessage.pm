package App::GitHooks::Plugin::RequireCommitMessage;

use strict;
use warnings;

use base 'App::GitHooks::Plugin';

# Internal dependencies.
use App::GitHooks::Constants qw( :PLUGIN_RETURN_CODES );
use App::GitHooks::Utils;


=head1 NAME

App::GitHooks::Plugin::RequireCommitMessage - Require a commit message.


=head1 DESCRIPTION

If you are using C<App::GitHooks::Plugin::RequireTicketID>, commit messages
will need to include a ticket ID but the rest of the commit message can be
empty. To prevent this, this plugin looks at the commit message, excluding the
ticket ID, and requires that it is not empty before allowing the commit to go
through.


=head1 VERSION

Version 1.2.0

=cut

our $VERSION = '1.2.0';


=head1 METHODS

=head2 run_commit_msg()

Code to execute as part of the commit-msg hook.

  my $success = App::GitHooks::Plugin::RequireCommitMessage->run_commit_msg();

=cut

sub run_commit_msg
{
	my ( $class, %args ) = @_;
	my $commit_message = delete( $args{'commit_message'} );
	my $app = delete( $args{'app'} );

	# Note: this allows catching the case where the ticket ID prefix was
	# auto-generated, but no message was entered by the user.
	my $summary = $commit_message->get_summary();
	my $ticket_regex = App::GitHooks::Utils::get_ticket_id_from_commit_regex( $app );
	$summary =~ s/$ticket_regex//i
		if defined( $ticket_regex );

	# We must have a message.
	if ( !defined( $summary ) || ( $summary !~ /\w/ ) )
	{
		my $failure_character = $app->get_failure_character();
		print $app->color( 'red', $failure_character . " You did not enter a commit message.\n" );
		return $PLUGIN_RETURN_FAILED;
	}

	return $PLUGIN_RETURN_PASSED;
}


=head1 BUGS

Please report any bugs or feature requests through the web interface at
L<https://github.com/guillaumeaubert/App-GitHooks-Plugin-RequireCommitMessage/issues/new>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc App::GitHooks::Plugin::RequireCommitMessage


You can also look for information at:

=over

=item * GitHub's request tracker

L<https://github.com/guillaumeaubert/App-GitHooks-Plugin-RequireCommitMessage/issues>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/app-githooks-plugin-requirecommitmessage>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/app-githooks-plugin-requirecommitmessage>

=item * MetaCPAN

L<https://metacpan.org/release/App-GitHooks-Plugin-RequireCommitMessage>

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
