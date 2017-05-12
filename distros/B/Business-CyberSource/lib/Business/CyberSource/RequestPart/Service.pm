package Business::CyberSource::RequestPart::Service;
use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.010008'; # VERSION

use Moose;
extends 'Business::CyberSource::MessagePart';
with    'MooseX::RemoteHelper::CompositeSerialization';

has run => (
	isa         => 'Bool',
	remote_name => 'run',
	is          => 'ro',
	lazy        => 1,
	init_arg    => undef,
	reader      => undef,
	writer      => undef,
	default     => sub { 1 },
	serializer  => sub {
		my ( $attr, $instance ) = @_;
		return $attr->get_value( $instance ) ? 'true' : 'false';
	},
);

__PACKAGE__->meta->make_immutable;
1;

# ABSTRACT: Service Request Part

__END__

=pod

=encoding UTF-8

=head1 NAME

Business::CyberSource::RequestPart::Service - Service Request Part

=head1 VERSION

version 0.010008

=head1 DESCRIPTION

Service provides support for the portion of requests that are named as
C<cc*Service> this tells CyberSource which type of request to make. All of the
L<Business::CyberSource::Request> based classes will add this correctly.
Depending on the request type you may have to set either
L<capture_request_id|/"capture_request_id"> or
L<auth_request_id|/"auth_request_id">

=head1 EXTENDS

L<Business::CyberSource::MessagePart>

=head1 ATTRIBUTES

=head2 run

run will be set correctly by default on ever request

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
