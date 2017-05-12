package Business::CyberSource::Request::AuthReversal;
use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.010008'; # VERSION

use Moose;
extends 'Business::CyberSource::Request';

use MooseX::Types::CyberSource qw( AuthReversalService );

has '+service' => (
	isa         => AuthReversalService,
	remote_name => 'ccAuthReversalService',
	lazy_build  => 0,
);

__PACKAGE__->meta->make_immutable;
1;

# ABSTRACT: CyberSource Reverse Authorization request object

__END__

=pod

=encoding UTF-8

=head1 NAME

Business::CyberSource::Request::AuthReversal - CyberSource Reverse Authorization request object

=head1 VERSION

version 0.010008

=head1 SYNOPSIS

	use Business::CyberSource::Request::AuthReversal;

	my $req = Business::CyberSource::Request::AuthReversal->new({
		reference_code => 'orignal authorization merchant reference code',
		service        => {
			request_id => 'request id returned by authorization',
		},
		purchase_totals {
			total          => 5.00, # same as original authorization amount
			currency       => 'USD', # same as original currency
		},
	});

=head1 DESCRIPTION

This allows you to reverse an authorization request.

=head1 EXTENDS

L<Business::CyberSource::Request>

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
