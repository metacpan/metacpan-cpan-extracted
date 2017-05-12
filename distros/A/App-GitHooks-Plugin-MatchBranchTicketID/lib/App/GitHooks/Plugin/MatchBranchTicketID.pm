package App::GitHooks::Plugin::MatchBranchTicketID;

use strict;
use warnings;

use base 'App::GitHooks::Plugin';

# Internal dependencies.
use App::GitHooks::Utils;
use App::GitHooks::Constants qw( :PLUGIN_RETURN_CODES );


=head1 NAME

App::GitHooks::Plugin::MatchBranchTicketID - Detect discrepancies between the ticket ID specified by the branch name and the one in the commit message.


=head1 DESCRIPTION

C<App::GitHooks::Plugin::PrependTicketID> allows pulling ticket IDs from the
branch name. This way, if you're committing a lot, having a proper branch name
can save you a lot of time.

That said, you sometimes need to commit using a different ticket ID than what
the branch specifies. In order to prevent typos, this plugin will detect if the
ticket ID specified in the commit message doesn't match the ticket ID infered
from the branch name, and ask you to confirm that you want to proceed forward.


=head1 VERSION

Version 1.0.2

=cut

our $VERSION = '1.0.2';


=head1 CONFIGURATION OPTIONS

This plugin supports the following options in the main section of your
C<.githooksrc> file.

	project_prefixes = OPS, DEV, TEST
	extract_ticket_id_from_branch = /^($project_prefixes\d+)/
	normalize_branch_ticket_id = s/^(.*?)(\d+)$/\U$1-$2/
	extract_ticket_id_from_commit = /^($project_prefixes-\d+|--): /


=head2 project_prefixes

The list of valid ticket prefixes.

	project_prefixes = OPS, DEV, TEST


=head2 extract_ticket_id_from_branch

A regular expression with one capturing group that will extract the ticket ID
from a branch name.

	extract_ticket_id_from_branch = /^($project_prefixes\d+)/

In the example above, if a branch is named C<dev1293_my_new_feature>, the
regular expression will identify C<dev1293> as the ticket ID corresponding to
that branch.

Note that:

=over 4

=item *

Prefixes used for private branches are recognized properly and ignored
accordingly. In other words, both C<dev1293_my_new_feature> and
C<ga/dev1293_my_new_feature> will be identified as tied to C<dev1293> with the
regex above.

=item *

$project_prefixes is replaced at run time by the prefixes listed in the
C<project_prefixes> configuration option, to avoid duplication of information.

=back


=head2 normalize_branch_ticket_id

A replacement expression to normalize the ticket ID extracted with
C<extract_ticket_id_from_branch>.

	normalize_branch_ticket_id = s/^(.*?)(\d+)$/\U$1-$2/

In the example above, C<dev1293_my_new_feature> gave C<dev1293>, which is then
normalized as C<DEV-1293>.


=head2 extract_ticket_id_from_commit

A regular expression with one capturing group that will extract the ticket ID
from a commit message.

	extract_ticket_id_from_commit = /^($project_prefixes-\d+|--): /

Note that:

=over 4

=item *

$project_prefixes is replaced at run time by the prefixes listed in the
C<project_prefixes> configuration option, to avoid duplication of information.

=item *

The example above allows C<--> to indicate that no ticket ID is available. This allows an occasional commit without a ticket ID, while making it easy to identify / review later. But you can configure this regular expression to use C<NONE> or any other keyword instead.

=back


=head1 METHODS

=head2 run_commit_msg()

Code to execute as part of the commit-msg hook.

  my $success = App::GitHooks::Plugin::MatchBranchTicketID->run_commit_msg();

=cut

sub run_commit_msg
{
	my ( $class, %args ) = @_;
	my $commit_message = delete( $args{'commit_message'} );
	my $app = delete( $args{'app'} );
	my $repository = $app->get_repository();

	my $ticket_id = $commit_message->get_ticket_id();

	# If the branch specifies a ticket ID, and it doesn't match the ticket ID
	# found in the commit message, ask the user to confirm.
	my $branch_ticket_id = App::GitHooks::Utils::get_ticket_id_from_branch_name( $app );
	if ( defined( $ticket_id ) && defined( $branch_ticket_id ) && ( $branch_ticket_id ne $ticket_id ) )
	{
		print $app->color( 'red', "Your branch is referencing $branch_ticket_id, but your commit message references $ticket_id.\n" );
		# uncoverable branch true
		if ( $app->get_terminal()->is_interactive() )
		{
			print "Press <Enter> to continue committing with $ticket_id, or Ctrl-C to abort the commit.\n";
			my $input = <STDIN>; ## no critic (InputOutput::ProhibitExplicitStdin)
		}
		else
		{
			return $PLUGIN_RETURN_FAILED;
		}
	}

	return $PLUGIN_RETURN_PASSED;
}


=head1 BUGS

Please report any bugs or feature requests through the web interface at
L<https://github.com/guillaumeaubert/App-GitHooks-Plugin-MatchBranchTicketID/issues/new>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc App::GitHooks::Plugin::MatchBranchTicketID


You can also look for information at:

=over

=item * GitHub's request tracker

L<https://github.com/guillaumeaubert/App-GitHooks-Plugin-MatchBranchTicketID/issues>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/app-githooks-plugin-matchbranchticketid>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/app-githooks-plugin-matchbranchticketid>

=item * MetaCPAN

L<https://metacpan.org/release/App-GitHooks-Plugin-MatchBranchTicketID>

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
