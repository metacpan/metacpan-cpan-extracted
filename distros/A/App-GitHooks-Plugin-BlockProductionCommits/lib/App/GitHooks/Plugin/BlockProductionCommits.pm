package App::GitHooks::Plugin::BlockProductionCommits;

use strict;
use warnings;

use base 'App::GitHooks::Plugin';

# External dependencies.
use Carp qw( croak );

# Internal dependencies.
use App::GitHooks::Constants qw( :PLUGIN_RETURN_CODES );


=head1 NAME

App::GitHooks::Plugin::BlockProductionCommits - Prevent commits in a production environment.


=head1 DESCRIPTION

Committing in production means you've been developing in production. That just
sounds like a terrible idea.


=head1 VERSION

Version 1.2.0

=cut

our $VERSION = '1.2.0';


=head1 CONFIGURATION OPTIONS

This plugin supports the following options in the C<[BlockProductionCommits]>
section of your C<.githooksrc> file.

	[BlockProductionCommits]
	env_variable = my_environment
	env_safe_regex = /^development$/
	remotes_whitelist_regex = /\/my_production_tools_repository\.git$/


=head2 env_variable

The name of the environment variable to use to determine the environment.

	env_variable = my_environment


=head2 env_safe_regex

A regular expression that indicates that the environment is safe to commit when
it is matched.

	env_safe_regex = /^development$/

The example above only allow commits when C<$ENV{'my_environment'} =~ /^development$/>.


=head2 remotes_whitelist_regex

A regular expression that indicates that commits should be allowed even if the
environment is production as long as the git remote matches it.

This is particularly useful if you have many repositories on your production
machines, and one of them is used by automated tools that should still be
allowed to commit.

	remotes_whitelist_regex = /\/my_production_tools_repository\.git$/


=head1 METHODS

=head2 run_pre_commit()

Code to execute as part of the pre-commit hook.

  my $success = App::GitHooks::Plugin::BlockProductionCommits->run_pre_commit();

=cut

sub run_pre_commit
{
	my ( $class, %args ) = @_;
	my $app = delete( $args{'app'} );
	my $repository = $app->get_repository();
	my $config = $app->get_config();

	# Allow non-interactive tools to commit in production.
	my $is_interactive = defined( $config->get( 'testing', 'force_interactive' ) )
		? $config->get( 'testing', 'force_interactive' )
		: $app->get_terminal()->is_interactive();
	return $PLUGIN_RETURN_PASSED
		if !$is_interactive;

	# Check if the environment is safe to commit in.
	my $env_variable = $config->get( 'BlockProductionCommits', 'env_variable' );
	croak "You must define 'env_variable' in the [BlockProductionCommits] section of your githooksrc config"
		if !defined( $env_variable );
	my $env_value = $ENV{ $env_variable } // '';
	my $env_regex = $config->get_regex( 'BlockProductionCommits', 'env_safe_regex' );
	return $PLUGIN_RETURN_PASSED
		if $env_value =~ $env_regex;

	# Check for whitelisted remotes, in case some specific repositories should be
	# allowed to be committed to in production.
	my $remotes_whitelist_regex = $config->get_regex( 'BlockProductionCommits', 'remotes_whitelist_regex' );
	if ( defined( $remotes_whitelist_regex ) )
	{
		my $remotes = $repository->run( 'remote', '-v' );
		return $PLUGIN_RETURN_PASSED
			if $remotes =~ /$remotes_whitelist_regex/x;
	}

	my $failure_character = $app->get_failure_character();
	print $app->wrap(
		$app->color( 'red', "$failure_character Non-dev environment detected - please commit from your dev instead.\n" ),
		"",
	);
	return $PLUGIN_RETURN_FAILED;
}


=head1 BUGS

Please report any bugs or feature requests through the web interface at
L<https://github.com/guillaumeaubert/App-GitHooks-Plugin-BlockProductionCommits/issues/new>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc App::GitHooks::Plugin::BlockProductionCommits


You can also look for information at:

=over

=item * GitHub's request tracker

L<https://github.com/guillaumeaubert/App-GitHooks-Plugin-BlockProductionCommits/issues>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/app-githooks-plugin-blockproductioncommits>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/app-githooks-plugin-blockproductioncommits>

=item * MetaCPAN

L<https://metacpan.org/release/App-GitHooks-Plugin-BlockProductionCommits>

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
