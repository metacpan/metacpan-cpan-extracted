package Business::PaperlessTrans::RequestPart::Identification;
use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.002000'; # VERSION

use Moose;

extends 'MooseY::RemoteHelper::MessagePart';
with qw(
	MooseX::RemoteHelper::CompositeSerialization
	Business::PaperlessTrans::Role::State
	Business::PaperlessTrans::Role::Address
);

use MooseX::Types::Common::String  qw( NonEmptySimpleStr );
use MooseX::Types::Common::Numeric qw( SingleDigit       );
use MooseX::Types::DateTime        qw( DateTime          );

my $dt_fmt
	= sub {
		my ( $attr, $instance ) = @_;
		return $attr->get_value( $instance )->format_cldr('MM/dd/YYYY');
	};

has id_type => (
	isa         => SingleDigit,
	is          => 'ro',
	required    => 1,
	remote_name => 'IDType',
);

has number => (
	isa         => NonEmptySimpleStr,
	is          => 'ro',
	remote_name => 'Number',
	required    => 1,
);

has expiration => (
	isa         => DateTime,
	is          => 'ro',
	coerce      => 1,
	remote_name => 'Expiration',
	serializer  => $dt_fmt,
);

has date_of_birth => (
	isa         => DateTime,
	is          => 'ro',
	coerce      => 1,
	remote_name => 'DOB',
	serializer  => $dt_fmt,
);

__PACKAGE__->meta->make_immutable;
1;
# ABSTRACT: Identification

__END__

=pod

=head1 NAME

Business::PaperlessTrans::RequestPart::Identification - Identification

=head1 VERSION

version 0.002000

=head1 AUTHOR

Caleb Cushing <xenoterracide@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Caleb Cushing.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
