package App::GitHooks::Utils;

use strict;
use warnings;

# External dependencies.
use Carp;
use File::Spec;
use Try::Tiny;

# No internal dependencies - keep this as a leaf module in the graph so that we
# can include it everywhere.


=head1 NAME

App::GitHooks::Utils - Support functions for App::GitHooks and its plugins.


=head1 VERSION

Version 1.9.0

=cut

our $VERSION = '1.9.0';


=head1 FUNCTIONS

=head2 get_project_prefixes()

Get an arrayref of valid project prefixes.

	my $project_prefixes = App::GitHooks::Utils::get_project_prefixes( $app );

Arguments:

=over 4

=item * $app

An C<App::GitHooks> instance.

=back

=cut

sub get_project_prefixes
{
	my ( $app ) = @_;
	my $config_line = $app->get_config()->{'_'}->{'project_prefixes'} // '';

	# Strip leading/trailing whitespace.
	$config_line =~ s/(?:^\s+|\s+$)//g;

	return [ split( /\s*[, ]\s*/, $config_line ) ];
}


=head2 get_project_prefix_regex()

Return a non-capturing regex that will match all the valid project prefixes.

	my $project_prefix_regex = App::GitHooks::Utils::get_project_prefix_regex( $app );

Arguments:

=over 4

=item * $app

An C<App::GitHooks> instance.

=back

=cut

sub get_project_prefix_regex
{
	my ( $app ) = @_;

	my $prefixes = get_project_prefixes( $app );

	if ( scalar( @$prefixes ) == 0 )
	{
		return '';
	}
	elsif ( scalar( @$prefixes ) == 1 )
	{
		return $prefixes->[0];
	}
	else
	{
		return '(?:' . join( '|', @$prefixes ) . ')';
	}
}


=head2 get_ticket_id_from_commit_regex()

Return a regex that will extract a ticket ID from a commit message, if it
exists.

	my $ticket_id_regex = App::GitHooks::Utils::get_ticket_id_from_commit_regex( $app );

Arguments:

=over 4

=item * $app

An C<App::GitHooks> instance.

=back

=cut

sub get_ticket_id_from_commit_regex
{
	my ( $app ) = @_;
	my $config = $app->get_config();

	# Retrieve the regular expression from the config or use a default.
	my $ticket_regex = $app->get_config()->get_regex( '_', 'extract_ticket_id_from_commit' )
		// '^($project_prefixes-\d+|--)\: ?';

	# Replace the list of project prefixes if it is mentioned in the regex.
	my $project_prefix_regex = get_project_prefix_regex( $app );
	$ticket_regex =~ s/\$project_prefixes/$project_prefix_regex/g;

	return $ticket_regex;
}


=head2 get_ticket_id_from_branch_name()

Return the ticket ID derived from the name of the current branch for this
repository.

	my $ticket_id = App::GitHooks::Utils::get_ticket_id_from_branch_name( $app );

Arguments:

=over 4

=item * $app

An C<App::GitHooks> instance.

=back

=cut

sub get_ticket_id_from_branch_name
{
	my ( $app ) = @_;
	my $repository = $app->get_repository();
	my $config = $app->get_config();

	# If the config doesn't specify a way to extract the ticket ID from the
	# branch, there's nothing we can do here.
	my $ticket_regex = $config->get_regex( '_', 'extract_ticket_id_from_branch' );
	return undef
		if !defined( $ticket_regex );

	# Check if we're in a rebase. During a rebase (regardless of whether it's
	# interractive or not), the HEAD goes in a detached state, and we won't be
	# able to call symbolic-ref on it to get a branch name.
	my $git_directory = $repository->git_dir();
	return undef
		if ( -d File::Spec->catfile( $git_directory, 'rebase-merge' ) ) # detect rebase -i
			|| ( -d File::Spec->catfile( $git_directory, 'rebase-apply' ) ); # detect rebase

	my $ticket_id;
	try
	{

		# Retrieve the branch name.
		my $branch_name = $repository->run('symbolic-ref', 'HEAD');
		my ( $branch_name_without_prefixes ) = $branch_name =~ /([^\/]+)$/;

		# Extract the ticket ID from the branch name.
		my $project_prefix_regex = get_project_prefix_regex( $app );
		$ticket_regex =~ s/\$project_prefixes/$project_prefix_regex/g;
		( $ticket_id ) = $branch_name_without_prefixes =~ /$ticket_regex/i;

		my $normalize = $config->get( '_', 'normalize_branch_ticket_id' );
		if ( defined( $ticket_id ) && defined( $normalize ) && ( $normalize =~ /\S/ ) )
		{
			my ( $match, $replacement ) = $normalize =~ m|^\s*s/(.*?)(?<!\\)/(.*)/\s*|x;
			croak "Invalid format for 'normalize_branch_ticket_id' in configuration file."
				if !defined( $match ) || !defined( $replacement );
			croak "Unsafe matching pattern in 'normalize_branch_ticket_id', escape your slashes"
				if $match =~ /(?<!\\)\//;
			croak "Unsafe replacement pattern in 'normalize_branch_ticket_id', escape your slashes"
				if $replacement =~ /(?<!\\)\//;
			eval( "\$ticket_id =~ s/$match/$replacement/i" ); ## no critic (BuiltinFunctions::ProhibitStringyEval, ErrorHandling::RequireCheckingReturnValueOfEval)
		}
	}
	catch
	{
		carp "ERROR: $_";
	};

	return $ticket_id;
}


=head1 BUGS

Please report any bugs or feature requests through the web interface at
L<https://github.com/guillaumeaubert/App-GitHooks/issues/new>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc App::GitHooks::Utils


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
