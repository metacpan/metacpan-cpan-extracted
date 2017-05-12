package App::GitHooks::Plugin::PerlCompile;

use strict;
use warnings;

use base 'App::GitHooks::Plugin';

# External dependencies.
use File::Spec qw();
use System::Command;

# Internal dependencies.
use App::GitHooks::Constants qw( :PLUGIN_RETURN_CODES );


=head1 NAME

App::GitHooks::Plugin::PerlCompile - Verify that Perl files compile without errors.


=head1 DESCRIPTION

This plugin verifies that staged Perl files compile without errors before
allowing the commit to be completed.


=head1 VERSION

Version 1.1.1

=cut

our $VERSION = '1.1.1';


=head1 CONFIGURATION OPTIONS

This plugin supports the following options in the C<[PerlCompile]> section of
your C<.githooksrc> file.

	[PerlCompile]
	lib_paths = ./lib, ./t/lib


=head2 lib_paths

This option gives an opportunity to include other paths to Perl libraries, and
in particular paths that are local to the current repository. It allows testing
that the Perl files compile without having to amend PERL5LIB to include the
repository-specific libraries.

	lib_paths = ./lib, ./t/lib


=head1 METHODS

=head2 get_file_pattern()

Return a pattern to filter the files this plugin should analyze.

	my $file_pattern = App::GitHooks::Plugin::PerlCompile->get_file_pattern(
		app => $app,
	);

=cut

sub get_file_pattern
{
	return qr/\.(?:pl|pm|t|cgi)$/x;
}


=head2 get_file_check_description()

Return a description of the check performed on files by the plugin and that
will be displayed to the user, if applicable, along with an indication of the
success or failure of the plugin.

	my $description = App::GitHooks::Plugin::PerlCompile->get_file_check_description();

=cut

sub get_file_check_description
{
	return 'The file passes perl -c';
}


=head2 run_pre_commit_file()

Code to execute for each file as part of the pre-commit hook.

  my $success = App::GitHooks::Plugin::PerlCompile->run_pre_commit_file();

=cut

sub run_pre_commit_file
{
	my ( $class, %args ) = @_;
	my $file = delete( $args{'file'} );
	my $git_action = delete( $args{'git_action'} );
	my $app = delete( $args{'app'} );
	my $repository = $app->get_repository();
	my $config = $app->get_config();

	# Ignore deleted files.
	return $PLUGIN_RETURN_SKIPPED
		if $git_action eq 'D';

	# Prepare extra libs specified in .githooksrc.
	my $lib_paths = $config->get( 'PerlCompile', 'lib_paths' );
	my @lib = map { ( '-I', $_ ) } split( /\s*,\s*/, $lib_paths // '' );

	# Execute perl -cw.
	my $path = File::Spec->catfile( $repository->work_tree(), $file );
	my ( $pid, $stdin, $stdout, $stderr ) = System::Command->spawn( $^X, '-cw', @lib, $path );

	# Retrieve the output.
	my $output;
	{
		local $/ = undef;
		$output = <$stderr>;
		chomp( $output );
	}

	# Raise an exception if we didn't get "syntax OK".
	die "$output\n"
		if $output !~ /\Q$file syntax OK\E$/x;

	return $PLUGIN_RETURN_PASSED;
}


=head1 BUGS

Please report any bugs or feature requests through the web interface at
L<https://github.com/guillaumeaubert/App-GitHooks-Plugin-PerlCompile/issues/new>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc App::GitHooks::Plugin::PerlCompile


You can also look for information at:

=over

=item * GitHub's request tracker

L<https://github.com/guillaumeaubert/App-GitHooks-Plugin-PerlCompile/issues>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/app-githooks-plugin-perlcompile>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/app-githooks-plugin-perlcompile>

=item * MetaCPAN

L<https://metacpan.org/release/App-GitHooks-Plugin-PerlCompile>

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
