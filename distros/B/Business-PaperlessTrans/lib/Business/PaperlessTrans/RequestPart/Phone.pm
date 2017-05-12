package Business::PaperlessTrans::RequestPart::Phone;
use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.002000'; # VERSION

use Moose;

extends 'MooseY::RemoteHelper::MessagePart';

use MooseX::Types::Common::String qw( NonEmptySimpleStr );

has number => (
	remote_name => 'Number',
	isa         => NonEmptySimpleStr,
	is          => 'ro',
);

has type => (
	remote_name => 'Type',
	isa         => NonEmptySimpleStr,
	is          => 'ro',
);

__PACKAGE__->meta->make_immutable;
1;
# ABSTRACT: Phone

__END__

=pod

=head1 NAME

Business::PaperlessTrans::RequestPart::Phone - Phone

=head1 VERSION

version 0.002000

=head1 AUTHOR

Caleb Cushing <xenoterracide@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Caleb Cushing.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
