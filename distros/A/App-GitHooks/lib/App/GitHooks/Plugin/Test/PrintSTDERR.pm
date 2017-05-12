package App::GitHooks::Plugin::Test::PrintSTDERR;

use strict;
use warnings;

use base 'App::GitHooks::Plugin';

# External dependencies.
use Carp;

# Internal dependencies.
use App::GitHooks::Constants qw( :PLUGIN_RETURN_CODES );


=head1 NAME

App::GitHooks::Plugin::Test::PrintSTDERR - A test plugin that allows printing a specific string to STDERR.


=head1 DESCRIPTION


=head1 SYNOPSIS

	use App::GitHooks::Plugin::Test::PrintSTDERR;

	# In .githooksrc.
	# [Test::PrintSTDERR]
	# pre-commit = Triggered a pre-commit plugin!
	# prepare-commit-msg = Triggered a prepare-commit-msg plugin!

	# Run hooks calling the plugin.


=head1 VERSION

Version 1.9.0

=cut

our $VERSION = '1.9.0';

our $HOOK_REPLIES;


=head1 METHODS

=head2 get_file_pattern()

Return a pattern to filter the files this plugin should analyze.

	my $file_pattern = App::GitHooks::Plugin::Test::PrintSTDERR->get_file_pattern(
		app => $app,
	);

=cut

sub get_file_pattern
{
	return qr//x;
}


=head2 get_file_check_description()

Return a description of the check performed on files by the plugin and that
will be displayed to the user, if applicable, along with an indication of the
success or failure of the plugin.

	my $description = App::GitHooks::Plugin::Test::PrintSTDERR->get_file_check_description();

=cut

sub get_file_check_description
{
	return 'Test plugin - print on STDERR.';
}


=head1 SUPPORTED HOOKS

This plugin supports all the hooks defined in C<App::GitHooks::Hook::*>,
including file-level checks for the appropriate hooks.

=over 4

=item run_applypatch_msg

=item run_commit_msg

=item run_post_applypatch

=item run_post_checkout

=item run_post_commit

=item run_post_merge

=item run_post_receive

=item run_post_rewrite

=item run_post_update

=item run_pre_applypatch

=item run_pre_auto_gc

=item run_pre_commit

=item run_pre_commit_file

=item run_pre_push

=item run_pre_rebase

=item run_pre_receive

=item run_prepare_commit_msg

=item run_update

=back

=cut

foreach my $hook ( @$App::GitHooks::Plugin::SUPPORTED_SUBS )
{
	no strict 'refs'; ## no critic (TestingAndDebugging::ProhibitNoStrict)
	my $sub = 'run_' . $hook;
	*$sub = sub
	{
		my ( $class, %args ) = @_;
		my $app = delete( $args{'app'} );
		my $config = $app->get_config();

		my $return = $config->get( 'Test::PrintSTDERR', $hook ) // '';
		croak "No test to print on STDERR specified for >$hook<."
			if $return !~ /\w/;
		print STDERR "$return\n";

		return $PLUGIN_RETURN_PASSED;
	};
}


=head1 BUGS

Please report any bugs or feature requests through the web interface at
L<https://github.com/guillaumeaubert/App-GitHooks/issues/new>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc App::GitHooks::Plugin::Test::PrintSTDERR


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
