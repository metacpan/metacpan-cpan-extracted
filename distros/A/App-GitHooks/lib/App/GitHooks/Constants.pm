package App::GitHooks::Constants;

use strict;
use warnings;

# External dependencies.
use base 'Exporter';
use Readonly;


=head1 NAME

App::GitHooks::Constants - Constants used by various modules in the App::GitHooks namespace.


=head1 VERSION

Version 1.9.0

=cut

our $VERSION = '1.9.0';


=head1 VARIABLES

=head2 Plugin return values

=over 4

=item * C<$PLUGIN_RETURN_FAILED>

Indicates that the checks performed by the plugin did not pass.

=item * C<$PLUGIN_RETURN_SKIPPED>

Indicates that the checks performed by the plugin were skipped.

=item * C<$PLUGIN_RETURN_WARNED>

Indicates that the checks performed by the plugins didn't fail, but they didn't
pass cleanly either and warnings were returned.

=item * C<$PLUGIN_RETURN_PASSED>

Indicates that the checks performed by the plugin passed and no warn.

=back

=cut

Readonly::Scalar our $PLUGIN_RETURN_FAILED  => -1;
Readonly::Scalar our $PLUGIN_RETURN_SKIPPED => 0;
Readonly::Scalar our $PLUGIN_RETURN_PASSED  => 1;
Readonly::Scalar our $PLUGIN_RETURN_WARNED  => 2;


=head2 Hook exit codes

=over 4

=item * C<$HOOK_EXIT_SUCCESS>

Indicates that the hook executed successfully.

=item * C<$HOOK_EXIT_FAILURE>

Indicates that the hook failed to execute correctly.

=back

=cut

Readonly::Scalar our $HOOK_EXIT_SUCCESS => 0;
Readonly::Scalar our $HOOK_EXIT_FAILURE => 1;


=head1 EXPORT TAGS

=over 4

=item * C<:PLUGIN_RETURN_CODES>

Exports C<$PLUGIN_RETURN_FAILED>, C<$PLUGIN_RETURN_SKIPPED>, and C<$PLUGIN_RETURN_PASSED>.

=item * C<:HOOK_EXIT_CODES>

Exports C<$HOOK_EXIT_SUCCESS>, C<$HOOK_EXIT_FAILURE>.

=back

=cut

# Exportable variables.
our @EXPORT_OK = qw(
	$PLUGIN_RETURN_FAILED
	$PLUGIN_RETURN_SKIPPED
	$PLUGIN_RETURN_PASSED
	$PLUGIN_RETURN_WARNED
	$HOOK_EXIT_SUCCESS
	$HOOK_EXIT_FAILURE
);

# Exported tags.
our %EXPORT_TAGS =
(
	PLUGIN_RETURN_CODES =>
	[
		qw(
			$PLUGIN_RETURN_FAILED
			$PLUGIN_RETURN_SKIPPED
			$PLUGIN_RETURN_PASSED
			$PLUGIN_RETURN_WARNED
		)
	],
	HOOK_EXIT_CODES     =>
	[
		qw(
			$HOOK_EXIT_SUCCESS
			$HOOK_EXIT_FAILURE
		)
	],
);


=head1 BUGS

Please report any bugs or feature requests through the web interface at
L<https://github.com/guillaumeaubert/App-GitHooks/issues/new>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc App::GitHooks::Constants


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
