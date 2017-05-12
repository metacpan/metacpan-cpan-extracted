package Business::PaperlessTrans::RequestPart::Check;
use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.002000'; # VERSION

use Moose;

extends 'MooseY::RemoteHelper::MessagePart';
with qw(
	MooseX::RemoteHelper::CompositeSerialization
	Business::PaperlessTrans::Role::NameOnAccount
	Business::PaperlessTrans::Role::Address
	Business::PaperlessTrans::Role::Identification
	Business::PaperlessTrans::Role::EmailAddress
);

use MooseX::Types::Common::String qw( NumericCode );

has routing_number => (
	remote_name => 'RoutingNumber',
	isa         => NumericCode,
	is          => 'ro',
	required    => 1,
);

has account_number => (
	remote_name => 'AccountNumber',
	isa         => NumericCode,
	is          => 'ro',
	required    => 1,
);

has phone_1 => (
	remote_name => 'Phone_1',
	isa         => 'Business::PaperlessTrans::RequestPart::Phone',
	is          => 'ro',
);

has phone_2 => (
	remote_name => 'Phone_2',
	isa         => 'Business::PaperlessTrans::RequestPart::Phone',
	is          => 'ro',
);

__PACKAGE__->meta->make_immutable;
1;
# ABSTRACT: Check

__END__

=pod

=head1 NAME

Business::PaperlessTrans::RequestPart::Check - Check

=head1 VERSION

version 0.002000

=head1 AUTHOR

Caleb Cushing <xenoterracide@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Caleb Cushing.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
