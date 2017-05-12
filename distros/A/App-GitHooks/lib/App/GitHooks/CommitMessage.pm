package App::GitHooks::CommitMessage;

use strict;
use warnings;

# External dependencies.
use Carp;
use Data::Validate::Type;

# Internal dependencies.
use App::GitHooks::Utils;


=head1 NAME

App::GitHooks::CommitMessage - A git commit message.


=head1 VERSION

Version 1.9.0

=cut

our $VERSION = '1.9.0';


=head1 METHODS

=head2 new()

	my $commit_message = App::GitHooks::CommitMessage->new(
		app     => $app,
		message => $message,
	);

Arguments:

=over 4

=item * app I<(mandatory)>

An C<App::GitHook> instance.

=item * message I<(mandatory)>

The commit message.

=back

=cut

sub new
{
	my ( $class, %args ) = @_;
	my $message = delete( $args{'message'} );
	my $app = delete( $args{'app'} );

	# Check arguments.
	croak 'A "message" argument is mandatory'
		if !defined( $message );
	croak 'An "app" argument is mandatory'
		if !Data::Validate::Type::is_instance( $app, class => 'App::GitHooks' );
	croak 'Unknown arguments: ' . join( ', ', keys( %args ) )
		if scalar( keys %args ) != 0;

	# Create a new instance.
	return bless(
		{
			message          => $message,
			original_message => $message,
			app              => $app,
		},
		$class,
	);
}


=head2 update_message()

Update the commit message.

	my $success = $commit_message->update_message( $new_message );

=cut

sub update_message
{
	my ( $self, $message ) = @_;

	# Update the message.
	$self->{'message'} = $message;

	# Remove various caches.
	delete( $self->{'lines'} );
	delete( $self->{'ticket_id'} );

	return 1;
}


=head2 get_lines()

Return an arrayref of the lines that will be included in the commit message,
excluding blank lines and comments.

	my $lines = $commit_message->get_lines(
		include_comments    => $include_comments,    # default: 0
		include_blank_lines => $include_blank_lines, # default: 1
	);

=cut

sub get_lines
{
	my ( $self, %args ) = @_;
	my $include_comments = delete( $args{'include_comments'} ) // 0;
	my $include_blank_lines = delete( $args{'include_blank_lines'} ) // 1;

	my $message = $self->get_message();

	my @lines = split( /\n/, $message // '' );
	@lines = grep { $_ !~ /^#/ } @lines
		if !$include_comments;
	@lines = grep { $_ !~ /^\s*$/ } @lines
		if !$include_blank_lines;

	return \@lines;
}


=head2 get_summary()

Return the first line of the commit message.

	my $summary = $commit_message->get_summary();

=cut

sub get_summary
{
	my ( $self ) = @_;
	my $lines = $self->get_lines(
		include_comments    => 0,
		include_blank_lines => 1,
	);

	return scalar( @$lines ) == 0
		? undef
		: $lines->[0];
}


=head2 is_empty()

Indicate whether a commit message is empty, after excluding comment lines and
blank lines.

	my $is_empty = $commit_message->is_empty();

=cut

sub is_empty
{
	my ( $self ) = @_;
	my $lines = $self->get_lines(
		include_comments    => 0,
		include_blank_lines => 0,
	);

	return scalar( @$lines ) == 0
		? 1
		: 0;
}


=head2 get_ticket_id()

Extract and return a ticket ID from the commit message.

	my $ticket_id = $commit_message->get_ticket_id();

=cut

sub get_ticket_id
{
	my ( $self ) = @_;
	my $message = $self->get_message();
	my $app = $self->get_app();

	if ( !defined( $self->{'ticket_id'} ) )
	{
		# Get regex to extract the ticket ID.
		my $ticket_regex = App::GitHooks::Utils::get_ticket_id_from_commit_regex( $app );

		# Parse the first line of the commit message.
		my $summary = $self->get_summary();
		my ( $ticket_id ) = $summary =~ /$ticket_regex/i;
		$self->{'ticket_id'} = $ticket_id;
	}

	return $self->{'ticket_id'};
}


=head2 has_changed()

Return whether the message has changed since the object was created.

	my $has_changed = $commit_message->has_changed();

=cut

sub has_changed
{
	my ( $self ) = @_;
	my $message = $self->get_message();
	my $original_message = $self->get_original_message();

	# If the defineness status doesn't match, it's definitely a change.
	return 1
		if defined( $message ) xor defined( $original_message );

	# If both are undefined, there's no change.
	return 0
		if !defined( $message ) && !defined( $original_message );

	# Both are defined, and we need to compare the messages.
	return $message eq $original_message ? 0 : 1;
}


=head1 ACCESSORS

=head2 get_original_message()

Return the original message that was provided when the object was created.

	my $original_message = $commit_message->get_original_message();

=cut

sub get_original_message
{
	my ( $self ) = @_;

	return $self->{'original_message'};
}


=head2 get_message()

Return the commit message itself.

	my $message = $commit_message->get_message();

=cut

sub get_message
{
	my ( $self ) = @_;

	return $self->{'message'};
}


=head2 get_app()

Return the parent C<App::GitHooks> object.

	my $app = $commit_message->get_app();

=cut

sub get_app
{
	my ( $self ) = @_;

	return $self->{'app'};
}


=head1 BUGS

Please report any bugs or feature requests through the web interface at
L<https://github.com/guillaumeaubert/App-GitHooks/issues/new>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc App::GitHooks::CommitMessage


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
