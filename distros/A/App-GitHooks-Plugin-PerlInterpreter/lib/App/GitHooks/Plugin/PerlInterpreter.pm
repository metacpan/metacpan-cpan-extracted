package App::GitHooks::Plugin::PerlInterpreter;

use strict;
use warnings;

use base 'App::GitHooks::Plugin';

# External dependencies.
use autodie qw( open close );

# Internal dependencies.
use App::GitHooks::Constants qw( :PLUGIN_RETURN_CODES );


=head1 NAME

App::GitHooks::Plugin::PerlInterpreter - Enforce a specific Perl interpreter on the first line of Perl files.


=head1 DESCRIPTION

This plugin allows you to enforce a specific Perl interpreter on the first line
of Perl files. This is particularly useful if you have a system Perl and a more
modern PerlBrew installation on your system, and you want to make sure that
other developers don't invoke the system Perl by mistake.


=head1 VERSION

Version 1.2.0

=cut

our $VERSION = '1.2.0';


=head1 CONFIGURATION OPTIONS

This plugin supports the following options in the C<[PerlInterpreter]>
section of your C<.githooksrc> file.

	[PerlInterpreter]
	interpreter_regex = /^#!\/usr\/bin\/env perl$/
	recommended_interpreter = #!/usr/bin/env perl


=head2 interpreter_regex

A regular expression that, if matched, indicates a valid hashbang line for Perl
scripts.

	interpreter_regex = /^#!\/usr\/bin\/env perl$/


=head2 recommended_interpreter

An optional recommendation that will be displayed to the user when the hashbang
line is not valid. This will help users fix incorrect hashbang lines.

	recommended_interpreter = #!/usr/bin/env perl

When this option is specified, errors will then display:

	x The Perl interpreter line is correct
	    Invalid: #!perl
	    Recommended: #!/usr/bin/env perl


=head1 METHODS

=head2 get_file_pattern()

Return a pattern to filter the files this plugin should analyze.

	my $file_pattern = App::GitHooks::Plugin::PerlInterpreter->get_file_pattern(
		app => $app,
	);

=cut

sub get_file_pattern
{
	return qr/\.(?:pl|t|cgi)$/x;
}


=head2 get_file_check_description()

Return a description of the check performed on files by the plugin and that
will be displayed to the user, if applicable, along with an indication of the
success or failure of the plugin.

	my $description = App::GitHooks::Plugin::PerlInterpreter->get_file_check_description();

=cut

sub get_file_check_description
{
	return 'The Perl interpreter line is correct';
}


=head2 run_pre_commit_file()

Code to execute for each file as part of the pre-commit hook.

  my $success = App::GitHooks::Plugin::PerlInterpreter->run_pre_commit_file();

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

	# Retrieve the first line.
	my $path = $repository->work_tree() . '/' . $file;
	open( my $file_handle, '<', $path );
	my $first_line = <$file_handle>;
	close( $file_handle );
	chomp( $first_line );

	# Verify the interpreter.
	my $interpreter_regex = $config->get_regex( 'PerlInterpreter', 'interpreter_regex' );
	die "The [PerlInterpreter] section of your config file is missing a 'interpreter_regex' key.\n"
		if !defined( $interpreter_regex ) || ( $interpreter_regex !~ /\w/ );

	if ( $first_line !~ /$interpreter_regex/ )
	{
		my $error = "Invalid: $first_line\n";

		my $recommended_interpreter = $config->get( 'PerlInterpreter', 'recommended_interpreter' );
		$error .= "Recommended: $recommended_interpreter\n"
			if defined( $recommended_interpreter );

		chomp( $error );
		die "$error\n";
	}

	return $PLUGIN_RETURN_PASSED;
}


=head1 BUGS

Please report any bugs or feature requests through the web interface at
L<https://github.com/guillaumeaubert/App-GitHooks-Plugin-PerlInterpreter/issues/new>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc App::GitHooks::Plugin::PerlInterpreter


You can also look for information at:

=over

=item * GitHub's request tracker

L<https://github.com/guillaumeaubert/App-GitHooks-Plugin-PerlInterpreter/issues>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/app-githooks-plugin-perlinterpreter>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/app-githooks-plugin-perlinterpreter>

=item * MetaCPAN

L<https://metacpan.org/release/App-GitHooks-Plugin-PerlInterpreter>

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
