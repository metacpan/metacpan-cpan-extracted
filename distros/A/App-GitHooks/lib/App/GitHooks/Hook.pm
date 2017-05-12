package App::GitHooks::Hook;

use strict;
use warnings;

# External dependencies.
use Carp;
use Try::Tiny;

# Internal dependencies.
use App::GitHooks::Constants qw( :HOOK_EXIT_CODES :PLUGIN_RETURN_CODES );


=head1 NAME

App::GitHooks::Hook - Base class for all git hook handlers.


=head1 VERSION

Version 1.9.0

=cut

our $VERSION = '1.9.0';


=head1 METHODS

=head2 run()

Run the hook handler and return an exit status to pass to git.

	my $exit_status = App::GitHooks::Hook->run(
		app => $app,
	);

Arguments:

=over 4

=item * app I<(mandatory)>

An L<App::GitHooks> object.

=item * stdin I<(optional)>

An arrayref of lines retrieved from SDTIN.

See for example the C<pre-push> hook for uses of this argument.

=back

=cut

sub run
{
	my ( $class, %args ) = @_;
	my $app = $args{'app'};
	my $stdin = $args{'stdin'};

	# Find all the plugins that are applicable for this hook.
	my $plugins = $app->get_hook_plugins( $app->get_hook_name() );

	# Run all the plugins.
	my $has_errors = 0;
	foreach my $plugin ( @$plugins )
	{
		# Since Perl doesn't allow dashes in method names but git hook names have
		# dashes, we need to make sure we convert dashes to underscores when
		# generating the method name to run.
		my $method = 'run_' . $app->get_hook_name();
		$method =~ s/-/_/g;

		# Run the plugin method corresponding to this hook.
		# If the plugin throws an exception, print the error message and consider
		# the return code to be a failure.
		my $return_code = try
		{
			return $plugin->$method(
				app   => $app,
				stdin => $stdin,
			);
		}
		catch
		{
			chomp( $_ );
			my $failure_character = $app->get_failure_character();
			print $app->color( 'red', "$failure_character $_\n" );
			return $PLUGIN_RETURN_FAILED;
		};

		$has_errors = 1
			if $return_code == $PLUGIN_RETURN_FAILED;
	}

	# Return an exit code for Git.
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

	perldoc App::GitHooks::Hook


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
