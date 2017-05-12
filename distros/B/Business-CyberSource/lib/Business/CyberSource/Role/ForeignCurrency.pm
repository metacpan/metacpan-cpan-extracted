package Business::CyberSource::Role::ForeignCurrency;
use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.010008'; # VERSION

use Moose::Role;
use MooseX::RemoteHelper;

use MooseX::SetOnce 0.200001;

use MooseX::Types::Locale::Currency qw( CurrencyCode );
use MooseX::Types::Common::Numeric  qw( PositiveOrZeroNum );

has foreign_currency => (
	isa         => CurrencyCode,
	remote_name => 'foreignCurrency',
	predicate   => 'has_foreign_currency',
	traits      => ['SetOnce'],
	is          => 'rw',
);

has foreign_amount => (
	isa         => PositiveOrZeroNum,
	remote_name => 'foreignAmount',
	predicate   => 'has_foreign_amount',
	traits      => ['SetOnce'],
	is          => 'rw',
);

has exchange_rate => (
	isa         => PositiveOrZeroNum,
	remote_name => 'exchangeRate',
	predicate   => 'has_exchange_rate',
	traits      => ['SetOnce'],
	is          => 'rw',
);

has exchange_rate_timestamp => (
	isa         => 'Str',
	remote_name => 'exchangeRateTimeStamp',
	predicate   => 'has_exchange_rate_timestamp',
	traits      => ['SetOnce'],
	is          => 'rw',
);

1;

# ABSTRACT: Role to apply to requests and responses that require currency

__END__

=pod

=encoding UTF-8

=head1 NAME

Business::CyberSource::Role::ForeignCurrency - Role to apply to requests and responses that require currency

=head1 VERSION

version 0.010008

=head1 ATTRIBUTES

=head2 foreign_currency

Billing currency returned by the DCC service. For the possible values, see the ISO currency codes

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
