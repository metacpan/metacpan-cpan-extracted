package Business::OnlinePayment::CyberSource;

use 5.010;
use strict;
use warnings;
use namespace::autoclean;

use Moose;
use Exception::Base;
use MooseX::NonMoose;
use MooseX::StrictConstructor;
use MooseX::Types::Moose qw(Bool HashRef Int);
use MooseX::Types::Common::String qw(NonEmptySimpleStr);

# ABSTRACT:  CyberSource backend for Business::OnlinePayment
our $VERSION = '3.000016'; # VERSION

extends 'Business::OnlinePayment';

#### Subroutine Definitions ####

# Post-construction hook
# Accepts:  A reference to a hash of construction parameters
# Returns:  Nothing

sub BUILD {
	my ( $self ) = @_;
	my $fields   = [ qw(type action reference_code amount) ];

	$self->required_fields( @$fields );

	return;
}

#### Object Attributes ####

#### Applied Roles ####

with 'Business::OnlinePayment::CyberSource::Role::TransactionHandling';

#### Method Modifiers ####

#### Meta class stuff ####

__PACKAGE__->meta->make_immutable();

1;

__END__

=pod

=head1 NAME

Business::OnlinePayment::CyberSource - CyberSource backend for Business::OnlinePayment

=head1 VERSION

version 3.000016

=head1 SYNOPSIS

	use Business::OnlinePayment;

	my $tx = Business::OnlinePayment->new( "CyberSource" );
	$tx->content(
		login          => 'username',
		password       => 'password',
		type           => 'CC',
		action         => 'Normal Authorization',
		invoice_number => '00000001', # MurchantReferenceCode
		first_name     => 'Peter',
		last_name      => 'Bowen',
		address        => '123 Anystreet',
		city           => 'Orem',
		state          => 'Utah',
		zip            => '84097',
		country        => 'US',
		email          => 'foo@bar.net',
		card_number    => '4111111111111111',
		expiration     => '09/06',
		cvv2           => '1234', #optional
		amount         => '5.00',
		currency       => 'USD',
	);

	$tx->submit();

	if($tx->is_success()) {
		print "Card processed successfully: ".$tx->authorization."\n";
	} else {
		print "Card was rejected: ".$tx->error_message."\n";
	}

	####
	# Two step transaction, authorization and capture.
	# If you don't need to review order before capture, you can
	# process in one step as above.
	####

  $tx = Business::OnlinePayment->new("CyberSource");
	$tx->content(
		login          => 'username',
		password       => 'password',
		type           => 'CC',
		action         => 'Authorization Only',
		invoice_number  => 44544, # MurchantReferenceCode
		description     => 'Business::OnlinePayment visa test',
		amount          => '42.39',
		first_name      => 'Tofu',
		last_name       => 'Beast',
		address         => '123 Anystreet',
		city            => 'Anywhere',
		state           => 'Utah',
		zip             => '84058',
		country         => 'US',
		email           => 'tofu@beast.org',
		card_number     => '4111111111111111',
		expiration      => '12/25',
		cvv2            => 1111,
	);
	$tx->submit();

	if($tx->is_success()) {
		# get information about authorization
		my $authorization = $tx->authorization();
		my $order_number = $tx->order_number(); # RequestId
		my $avs_code = $tx->avs_code(); # AVS Response Code();
		my $cvv2_response = $tx->cvv2_response(); # CVV2/CVC2/CID Response Code();

		# now capture transaction

		$tx->content(
			login          => 'username',
			password       => 'password',
			type           => 'CC',
			action         => 'Post Authorization',
			invoice_number => 44544, #MurchantReferenceCode
			amount         => '42.39',
			po_number       => $tx->order_number(), # RequestId
		);

		$tx->submit();

		if($tx->is_success()) {
			print "Funds captured successfully\n";
		} else {
			print "Card was rejected: ".$tx->error_message."\n";
		}

	} else {
		print "Card was rejected: " . $tx->error_message() . "\n";
	}

=head1 DESCRIPTION

For detailed information see L<Business::OnlinePayment>.

=head1 METHODS

=head2 BUILD

this is a before-construction hook for Moose.  You Will never call this method directly.

=head1 SUPPORTED TRANSACTION TYPES

=head2 CC

Content required: type, login, action, amount, first_name, last_name, card_number, expiration.

cvv2 is required in order to get back a cvv2_response value.

=head2 Settling

To settle an authorization-only transaction (where you set action to
C<Authorization Only>), submit the C<order_number> code in the field
C<po_number> with the action set to C<Post Authorization>.

You can get the transaction id from the authorization by calling the
C<order_number> method on the object returned from the authorization.
You must also submit the amount field with a value less than or equal
to the amount specified in the original authorization.

=head1 ACKNOWLEDGMENTS

=over 4

=item Jason Kohles

For writing BOP - I didn't have to create my own framework.

=item Ivan Kohler

Tested the first pre-release version and fixed a number of bugs.
He also encouraged me to add better error reporting for system
errors.  He also added failure_status support.

=item Jason (Jayce^) Hall

Adding Request Token Requirements (Among other significant improvements... )

=back

=head1 SEE ALSO

L<Business::OnlinePayment>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/xenoterracide/business-onlinepayment-cybersource/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHORS

=over 4

=item *

Jad Wauthier <Jadrien dot Wauthier at GMail dot com>

=item *

Caleb Cushing <xenoterracide@gmail.com>

=item *

Peter Bowen <peter@bowenfamily.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by L<HostGator.com|http://www.hostgator.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
