package App::GitHooks::Plugin::ValidatePODFormat;

use strict;
use warnings;

use base 'App::GitHooks::Plugin';

# External dependencies.
use Pod::Simple;

# Internal dependencies.
use App::GitHooks::Constants qw( :PLUGIN_RETURN_CODES );


=head1 NAME

App::GitHooks::Plugin::ValidatePODFormat - Validate POD format in Perl and POD files.


=head1 DESCRIPTION


=head1 VERSION

Version 1.1.0

=cut

our $VERSION = '1.1.0';


=head1 METHODS

=head2 get_file_pattern()

Return a pattern to filter the files this plugin should analyze.

	my $file_pattern = App::GitHooks::Plugin::ValidatePODFormat->get_file_pattern(
		app => $app,
	);

=cut

sub get_file_pattern
{
	return qr/\.(?:pl|pm|t|cgi|pod)$/x;
}


=head2 get_file_check_description()

Return a description of the check performed on files by the plugin and that
will be displayed to the user, if applicable, along with an indication of the
success or failure of the plugin.

	my $description = App::GitHooks::Plugin::ValidatePODFormat->get_file_check_description();

=cut

sub get_file_check_description
{
	return 'POD format is valid.';
}


=head2 run_pre_commit_file()

Code to execute for each file as part of the pre-commit hook.

  my $success = App::GitHooks::Plugin::ValidatePODFormat->run_pre_commit_file();

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

	# Ignore revert commits.
	return $PLUGIN_RETURN_SKIPPED
		if $staged_changes->is_revert();

	# Run the POD checker.
	my $checker = Pod::Simple->new();
	$checker->output_string( \my $trash ); # Ignore any output
	$checker->parse_file( $file );

	# If the POD checker reports an error, investigate.
	if ( $checker->any_errata_seen() ) {
		# Parse the errors.
		my @formatted_errors = ();
		my $lines = $checker->{errata};
		foreach my $line ( sort { $a <=> $b } keys %$lines ) {
			my $errors = $lines->{$line};
			push( @formatted_errors, map { "Line $line: $_" } @$errors );
		}

		# An error was reported but no specific error was found. This shouldn't
		# happen.
		die "POD parsing failed, but no specific error could be reported.\n"
			if scalar( @formatted_errors ) == 0;

		die join( "\n", @formatted_errors ), "\n";
	}

	return $PLUGIN_RETURN_PASSED;
}


=head1 BUGS

Please report any bugs or feature requests through the web interface at
L<https://github.com/guillaumeaubert/App-GitHooks-Plugin-ValidatePODFormat/issues/new>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc App::GitHooks::ValidatePODFormat


You can also look for information at:

=over

=item * GitHub's request tracker

L<https://github.com/guillaumeaubert/App-GitHooks-Plugin-ValidatePODFormat/issues>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/app-githooks-plugin-validatepodformat>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/app-githooks-plugin-validatepodformat>

=item * MetaCPAN

L<https://metacpan.org/release/App-GitHooks-Plugin-ValidatePODFormat>

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
