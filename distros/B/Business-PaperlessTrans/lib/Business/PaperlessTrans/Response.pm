package Business::PaperlessTrans::Response;
use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.002000'; # VERSION

use Moose;
extends 'MooseY::RemoteHelper::MessagePart';

use MooseX::Types::Common::String qw( SimpleStr );
use Moose::Util::TypeConstraints  qw( enum      );
use MooseX::Types::UUID           qw( UUID      );

has transaction_id => (
	remote_name => 'TransactionID',
	isa         => UUID|SimpleStr,
	is          => 'ro',
);

has code => (
	remote_name => 'ResponseCode',
	isa         => enum( [qw( 0 1 2 )] ),
	is          => 'ro',
);

has message => (
	remote_name => 'Message',
	isa         => SimpleStr,
	is          => 'ro',
);

has timestamp => (
	remote_name => 'DateTimeStamp',
	isa         => SimpleStr,
	is          => 'ro',
);

__PACKAGE__->meta->make_immutable;
1;
# ABSTRACT: Base Response

__END__

=pod

=head1 NAME

Business::PaperlessTrans::Response - Base Response

=head1 VERSION

version 0.002000

=head1 AUTHOR

Caleb Cushing <xenoterracide@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Caleb Cushing.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
