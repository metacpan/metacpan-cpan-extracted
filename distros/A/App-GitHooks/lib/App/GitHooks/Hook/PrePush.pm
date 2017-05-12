package App::GitHooks::Hook::PrePush;

use strict;
use warnings;

# Inherit from the base Hook class.
use base 'App::GitHooks::Hook';


=head1 NAME

App::GitHooks::Hook::PrePush - Handle the pre-push hook.


=head1 VERSION

Version 1.9.0

=cut

our $VERSION = '1.9.0';


=head1 METHODS

=head2 run()

Run the hook handler and return an exit status to pass to git.

	my $exit_status = App::GitHooks::Hook::PrePush->run(
		app => $app,
	);

Arguments:

=over 4

=item * app I<(mandatory)>

An App::GitHooks object.

=back

=cut

sub run
{
	my ( $class, %args ) = @_;

	# Retrieve stdin, which contains a list of the references being pushed.
	# It is important to do it once for the whole hook, and then pass it to the
	# plugins - otherwise the first plugin that reads stdin will leave it empty
	# for the others and they won't see any changes.
	$args{'stdin'} = [ <STDIN> ]; ## no critic (InputOutput::ProhibitExplicitStdin)

	return $class->SUPER::run(
		%args
	);
}


=head1 BUGS

Please report any bugs or feature requests through the web interface at
L<https://github.com/guillaumeaubert/App-GitHooks/issues/new>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc App::GitHooks::Hook::PrePush


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
