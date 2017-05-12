package Audit::DBI::Event;

use strict;
use warnings;

use Carp;
use Data::Validate::Type;
use Storable;
use MIME::Base64 qw();


=head1 NAME

Audit::DBI::Event - An event as logged by the Audit::DBI module.


=head1 VERSION

Version 1.9.0

=cut

our $VERSION = '1.9.0';


=head1 SYNOPSIS

	use Audit::DBI::Event;

	my $audit_event = Audit::DBI::Event->new(
		data => $data, #mandatory
	);

	my $audit_event_id = $audit_event->get_id();
	my $information = $audit_event->get_information();
	my $diff = $audit_event->get_diff();
	my $ipv4_address = $audit_event->get_ipv4_address();


=head1 METHODS

=head2 new()

Create a new Audit::DBI::Event object.

	my $audit_event = Audit::DBI::Event->new(
		data => $data, #mandatory
	);

Note that you should never have to instantiate Audit::DBI::Event objects
directly. They are normally created by the Audit::DBI module.

=cut

sub new
{
	my ( $class, %args ) = @_;
	my $data = delete( $args{'data'} );

	croak 'The parameter "data" is mandatory'
		if !defined( $data );
	croak 'The parameter "data" must be a hashref'
		if !Data::Validate::Type::is_hashref( $data );

	return bless( $data, $class );
}


=head1 ACCESSORS

=head2 get_id()

Return the audit event ID.

	my $audit_event_id = $audit_event->get_id();

=cut

sub get_id
{
	my ( $self ) = @_;

	return $self->{'audit_event_id'};
}


=head2 get_information()

Retrieve the extra information stored, if any.

	my $information = $audit_event->get_information();

=cut

sub get_information
{
	my ( $self ) = @_;

	return defined( $self->{'information'} )
		? Storable::thaw( MIME::Base64::decode_base64( $self->{'information'} ) )
		: undef;
}


=head2 get_diff()

Retrieve the diff information stored, if any.

	my $diff = $audit_event->get_diff();

=cut

sub get_diff
{
	my ( $self ) = @_;

	return defined( $self->{'diff'} )
		? Storable::thaw( MIME::Base64::decode_base64( $self->{'diff'} ) )
		: undef;
}


=head2 get_diff_string_bytes()

Return the size in bytes of all the text changes recorded inside the diff
information stored for the event.

This method can use two comparison types to calculate the size of the changes
inside a diff:

=over 4

=item * Relative comparison (by default):

In this case, a string change from 'TestABC' to 'TestCDE' is a 0 bytes
change (since there is the same number of characters).

	my $diff_bytes = $audit_event->get_diff_string_bytes();

=item * Absolute comparison:

In this case, a string change from 'TestABC' to 'TestCDE' is a 6 bytes
change (3 characters removed, and 3 added).

	my $diff_bytes = $audit_event->get_diff_string_bytes( absolute => 1 );

Note that absolute comparison requires L<String::Diff> to be installed.

=back

=cut

sub get_diff_string_bytes
{
	my ( $self, %args ) = @_;

	my $diff = $self->get_diff();
	return 0 if !defined( $diff );

	return Audit::DBI::Utils::get_diff_string_bytes(
		$diff,
		%args,
	);
}


=head2 get_ipv4_address()

Return the IPv4 address associated with the audit event.

	my $ipv4_address = $audit_event->get_ipv4_address();

=cut

sub get_ipv4_address
{
	my ( $self ) = @_;

	return Audit::DBI::Utils::integer_to_ipv4( $self->{'ipv4_address'} );
}


=head1 BUGS

Please report any bugs or feature requests through the web interface at
L<https://github.com/guillaumeaubert/Audit-DBI/issues/new>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Audit::DBI::Event


You can also look for information at:

=over 4

=item * GitHub's request tracker

L<https://github.com/guillaumeaubert/Audit-DBI/issues>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Audit-DBI>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Audit-DBI>

=item * MetaCPAN

L<https://metacpan.org/release/Audit-DBI>

=back


=head1 AUTHOR

L<Guillaume Aubert|https://metacpan.org/author/AUBERTG>,
C<< <aubertg at cpan.org> >>.


=head1 COPYRIGHT & LICENSE

Copyright 2010-2017 Guillaume Aubert.

This code is free software; you can redistribute it and/or modify it under the
same terms as Perl 5 itself.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the LICENSE file for more details.

=cut

1;
