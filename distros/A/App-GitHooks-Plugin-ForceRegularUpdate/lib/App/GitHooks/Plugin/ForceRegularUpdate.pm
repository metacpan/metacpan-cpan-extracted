package App::GitHooks::Plugin::ForceRegularUpdate;

use strict;
use warnings;

use base 'App::GitHooks::Plugin';

# External dependencies.
use Carp;
use File::Slurp ();

# Internal dependencies.
use App::GitHooks::Constants qw( :PLUGIN_RETURN_CODES );


=head1 NAME

App::GitHooks::Plugin::ForceRegularUpdate - Force running a specific tool at regular intervals.


=head1 DESCRIPTION

# TODO: description of how to write a tool that generates the timestamp file.


=head1 VERSION

Version 1.0.5

=cut

our $VERSION = '1.0.5';


=head1 CONFIGURATION OPTIONS

This plugin supports the following options in the C<[BlockProductionCommits]>
section of your C<.githooksrc> file.

	[BlockProductionCommits]
	max_update_age = 2 * 24 * 3600 # 2 days
	description = ./my_updater.sh
	env_variable = my_environment
	env_safe_regex = /^development$/
	update_file = /var/local/.last_update.txt

=head2 max_update_age

This indicates the maximum amount of time that may have elapsed since the last
update, before commits are blocked.

	max_update_age = 2 * 24 * 3600 # 2 days

Note that this configuration option supports comments at the end, for
readability.


=head2 description

The name of the tool to run to perform an update that will reset the time
counter.

	description = ./my_updater.sh


=head2 env_variable

Optional, the name of the environment variable to use to determine the
environment (production, staging, development, etc).

	env_variable = my_environment


=head2 env_regex

Optional, but required if C<env_variable> is used.

A regular expression that indicates that this plugin should be run when it is
matched.

	env_safe_regex = /^development$/

The example above only checks for regular updates when
C<$ENV{'my_environment'} =~ /^development$/>.


=head2 update_file

The path to the file that stores the unix time of the last upgrade. This is the
file your update tool should write the current unix time to upon successful
completion.

	update_file = /var/local/.last_update.txt

Note that you can use an absolute path, or a relative path. If relative, the
path will be relative to the root of the current git repository.


=head1 METHODS

=head2 run_pre_commit()

Code to execute as part of the pre-commit hook.

  my $success = App::GitHooks::Plugin::ForceRegularUpdate->run_pre_commit();

=cut

sub run_pre_commit
{
	my ( $class, %args ) = @_;
	my $app = delete( $args{'app'} );
	my $repository = $app->get_repository();
	my $config = $app->get_config();

	# Verify we have the max update age configured.
	my $max_update_age = $config->get( 'ForceRegularUpdate', 'max_update_age' );
	croak "'max_update_age' must be defined in the [ForceRegularUpdate] section of your .githooksrc file"
		if !defined $max_update_age;
	$max_update_age =~ s/^\s+//;
	$max_update_age =~ s/\s*(?:#.*)$//;
	croak "'max_update_age' in the [ForceRegularUpdate] section must be an integer expressing seconds"
		if $max_update_age !~ /^\d+$/;

	# Verify we have a description.
	my $description = $config->get( 'ForceRegularUpdate', 'description' );
	croak "'description' must be defined in the [ForceRegularUpdate] section of your .githooksrc file"
		if !defined( $description ) || ( $description !~ /\w/ );

	# Check if we have environment restrictions.
	my $env_variable = $config->get( 'ForceRegularUpdate', 'env_variable' );
	my $env_regex = $config->get_regex( 'ForceRegularUpdate', 'env_regex' );
	if ( defined( $env_variable ) )
	{
		croak "You defined an environment variable to check against, but not a regex to use, in the [ForceRegularUpdate] section"
			if !defined( $env_regex );

		return $PLUGIN_RETURN_SKIPPED
			if ( $ENV{ $env_variable } // '' ) !~ $env_regex;
	}

	# Retrieve the file that specifies the time of last update.
	my $update_file = $config->get( 'ForceRegularUpdate', 'update_file' );
	croak "'update_file' must be defined in the [ForceRegularUpdate] section of your .githooksrc file"
		if !defined( $update_file );
	$update_file =~ s/\$ENV\{'([^']+)'\}/$ENV{$1}/xeg;
	$update_file =~ s/\$ENV\{"([^"]+)"\}/$ENV{$1}/xeg;
	$update_file =~ s/\$ENV\{([^\}]+)\}/$ENV{$1}/xeg;

	# Check if the update was ever performed.
	my $failure_character = $app->get_failure_character();
	if ( ! -e $update_file )
	{
		print $app->wrap(
			$app->color( 'red', "$failure_character It appears that you have never performed $description on this machine - please do that before committing.\n" ),
			"",
		);
		return $PLUGIN_RETURN_FAILED;
	}

	# Retrieve the value of the file and check whether it's within the bounds
	# allowed.
	my $last_update = File::Slurp::read_file( $update_file );
	chomp( $last_update );
	if ( !defined( $last_update )                       # Invalid format.
	     || ( $last_update !~ /^\d+$/ )                 # Invalid format.
	     || ( $last_update < time() - $max_update_age ) # Not updated in a long time.
	     || ( $last_update > time() + 10 )              # Nice try setting the timestamp in the future to not have to update.
	)
	{
		print $app->wrap(
			$app->color(
				'red',
				"$failure_character It appears that you haven't performed $description on this machine for a long time. Please do that and try to commit again.\n"
			),
			"",
		);
		return $PLUGIN_RETURN_FAILED;
	}

	return $PLUGIN_RETURN_PASSED;
}


=head1 BUGS

Please report any bugs or feature requests through the web interface at
L<https://github.com/guillaumeaubert/App-GitHooks-Plugin-ForceRegularUpdate/issues/new>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc App::GitHooks::Plugin::ForceRegularUpdate


You can also look for information at:

=over

=item * GitHub's request tracker

L<https://github.com/guillaumeaubert/App-GitHooks-Plugin-ForceRegularUpdate/issues>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/app-githooks-plugin-forceregularupdate>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/app-githooks-plugin-forceregularupdate>

=item * MetaCPAN

L<https://metacpan.org/release/App-GitHooks-Plugin-ForceRegularUpdate>

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
