package Business::PaperlessTrans::Request;
use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.002000'; # VERSION

use Moose;
extends 'MooseY::RemoteHelper::MessagePart';

use Class::Load 0.20 'load_class';

with qw(
	MooseX::RemoteHelper::CompositeSerialization
);

has type => (
	isa     => 'Str',
	is      => 'ro',
	lazy    => 1,
	builder => '_build_type',
);

has custom_fields => (
	remote_name => 'CustomFields',
	isa         => 'Business::PaperlessTrans::RequestPart::CustomFields',
	is          => 'ro',
	default     => sub {
		load_class('Business::PaperlessTrans::RequestPart::CustomFields')->new
	},
);

__PACKAGE__->meta->make_immutable;
1;
# ABSTRACT: AuthorizeCard Request

__END__

=pod

=head1 NAME

Business::PaperlessTrans::Request - AuthorizeCard Request

=head1 VERSION

version 0.002000

=head1 AUTHOR

Caleb Cushing <xenoterracide@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Caleb Cushing.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
