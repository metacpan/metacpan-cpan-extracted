package Business::PaperlessTrans::RequestPart::Address;
use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.002000'; # VERSION

use Moose;

extends 'MooseY::RemoteHelper::MessagePart';

with qw(
	MooseX::RemoteHelper::CompositeSerialization
	Business::PaperlessTrans::Role::State
);

use MooseX::Types::Common::String qw( NonEmptySimpleStr );

has street => (
	isa         => NonEmptySimpleStr,
	is          => 'ro',
	remote_name => 'Street',
);

has city => (
	isa         => NonEmptySimpleStr,
	is          => 'ro',
	remote_name => 'City',
);

has country => (
	isa         => NonEmptySimpleStr,
	is          => 'ro',
	remote_name => 'Country',
);

has zip => (
	isa         => NonEmptySimpleStr,
	is          => 'ro',
	remote_name => 'Zip',
);

__PACKAGE__->meta->make_immutable;
1;
# ABSTRACT: Address

__END__

=pod

=head1 NAME

Business::PaperlessTrans::RequestPart::Address - Address

=head1 VERSION

version 0.002000

=head1 ATTRIBUTES

=head2 street

=head2 city

=head2 state

=head2 zip

=head2 country

=head1 AUTHOR

Caleb Cushing <xenoterracide@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Caleb Cushing.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
