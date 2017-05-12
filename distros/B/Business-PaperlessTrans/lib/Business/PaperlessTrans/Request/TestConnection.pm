package Business::PaperlessTrans::Request::TestConnection;
use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.002000'; # VERSION

use Moose;

extends 'MooseY::RemoteHelper::MessagePart';

with qw(
	MooseX::RemoteHelper::CompositeSerialization
);

sub _build_type {
	return 'TestConnection';
}

has type => (
	isa     => 'Str',
	is      => 'ro',
	lazy    => 1,
	builder => '_build_type',
);

__PACKAGE__->meta->make_immutable;
1;
# ABSTRACT: Test Connection

__END__

=pod

=head1 NAME

Business::PaperlessTrans::Request::TestConnection - Test Connection

=head1 VERSION

version 0.002000

=head1 DESCRIPTION

The Test Connection Request has a different API from other requests and
therefore does not inherit from Request, but conforms to the same external
interfaces.

=head1 AUTHOR

Caleb Cushing <xenoterracide@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Caleb Cushing.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
