package Business::CyberSource::Request::Role::TaxService;
use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.010008'; # VERSION

use Moose::Role;
use MooseX::SetOnce;
use MooseX::RemoteHelper;

use MooseX::Types::CyberSource qw( TaxService );

has tax_service => (
	isa         => TaxService,
	remote_name => 'taxService',
	is          => 'rw',
	traits      => ['SetOnce'],
	coerce      => 1,
);

1;

# ABSTRACT: Tax Service

__END__

=pod

=encoding UTF-8

=head1 NAME

Business::CyberSource::Request::Role::TaxService - Tax Service

=head1 VERSION

version 0.010008

=head1 ATTRIBUTES

=head2 tax_service

L<Business::CyberSource::RequestPart::Service::Tax> you can pass an empty hash
ref to the constructor, just to get the service to run.

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
