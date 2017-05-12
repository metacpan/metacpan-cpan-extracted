package App::GitHooks::Plugin;

use strict;
use warnings;

# External dependencies.
use Carp;


=head1 NAME

App::GitHooks::Plugin - Base class for plugins.


=head1 VERSION

Version 1.9.0

=cut

our $VERSION = '1.9.0';

our $SUPPORTED_SUBS =
[
	qw(
		applypatch_msg
		commit_msg
		post_applypatch
		post_checkout
		post_commit
		post_merge
		post_receive
		post_rewrite
		post_update
		pre_applypatch
		pre_auto_gc
		pre_commit
		pre_commit_file
		pre_push
		pre_rebase
		pre_receive
		prepare_commit_msg
		update
	)
];


=head1 METHODS

=head2 get_file_check_description()

Return a description of the check performed on files by the plugin and that
will be displayed to the user, if applicable, along with an indication of the
success or failure of the plugin.

	my $description = $plugin_class->get_file_check_description();

=cut

sub get_file_check_description
{
	croak 'You must define a get_file_check_description() subroutine in the plugin';
}


=head2 get_name()

Return the name of the plugin. For example, for C<App::GitHooks::Plugin::Test>,
the name will be C<Test>.

	my $name = $plugin->get_name();

=cut

sub get_name
{
	my ( $class ) = @_;
	croak 'You need to call this method on a class'
		if !defined( $class ) || ( $class eq '' );;

	my $base_path = __PACKAGE__ . '::';
	croak "Not a valid plugin class: >$class<"
		if $class !~ /^\Q$base_path\E/;

	$class =~ s/^$base_path//;

	return $class;
}


=head1 BUGS

Please report any bugs or feature requests through the web interface at
L<https://github.com/guillaumeaubert/App-GitHooks/issues/new>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc App::GitHooks::Plugin


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
