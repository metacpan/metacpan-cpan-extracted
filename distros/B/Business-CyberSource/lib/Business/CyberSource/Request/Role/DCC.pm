package Business::CyberSource::Request::Role::DCC;
use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.010008'; # VERSION

use Moose::Role;
use MooseX::RemoteHelper;
use MooseX::SetOnce 0.200001;

with 'Business::CyberSource::Role::ForeignCurrency';

use MooseX::Types::CyberSource qw( DCCIndicator );

has dcc_indicator => (
	isa         => DCCIndicator,
	remote_name => 'dcc',
	predicate   => 'has_dcc_indicator',
	traits      => [ 'SetOnce' ],
	is          => 'rw',
	serializer  => sub {
		my ( $attr, $instance ) = @_;
		return { dccIndicator => $attr->get_value( $instance ) };
	},
);

1;

# ABSTRACT: Role for DCC follow up requests

__END__

=pod

=encoding UTF-8

=head1 NAME

Business::CyberSource::Request::Role::DCC - Role for DCC follow up requests

=head1 VERSION

version 0.010008

=head1 DESCRIPTION

=head1 WITH

=over

=item L<Business::CyberSource::Role::ForeignCurrency>

=back

=head1 ATTRIBUTES

=head2 dcc_indicator

Flag that indicates whether DCC is being used for the transaction.

This field is required if you called the DCC service for the purchase.

Possible values:

=over

=item 1: Converted

DCC is being used.

=item 2: Nonconvertible

DCC cannot be used.

=item 3: Declined

DCC could be used, but the customer declined it.

=back

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/hostgator/business-cybersource/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Caleb Cushing <xenoterracide@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Caleb Cushing <xenoterracide@gmail.com>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
