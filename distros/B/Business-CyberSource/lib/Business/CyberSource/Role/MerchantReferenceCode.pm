package Business::CyberSource::Role::MerchantReferenceCode;
use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.010008'; # VERSION

use Moose::Role;
use MooseX::RemoteHelper;
use MooseX::Types::CyberSource qw( _VarcharFifty );

has reference_code => (
	isa         => _VarcharFifty,
	remote_name => 'merchantReferenceCode',
	required    => 1,
	is          => 'ro',
	predicate   => 'has_reference_code',
);

1;

# ABSTRACT: Generic implementation of MerchantReferenceCode

__END__

=pod

=encoding UTF-8

=head1 NAME

Business::CyberSource::Role::MerchantReferenceCode - Generic implementation of MerchantReferenceCode

=head1 VERSION

version 0.010008

=head1 ATTRIBUTES

=head2 reference_code

Merchant-generated order reference or tracking number. CyberSource recommends
that you send a unique value for each transaction so that you can perform
meaningful searches for the transaction.

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
