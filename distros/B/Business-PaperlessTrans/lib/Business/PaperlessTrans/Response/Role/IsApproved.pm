package Business::PaperlessTrans::Response::Role::IsApproved;
use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.002000'; # VERSION

use Moose::Role;
use MooseX::RemoteHelper;
use MooseX::RemoteHelper::Types qw( Bool );

has is_approved => (
	remote_name => 'IsApproved',
	isa         => Bool,
	is          => 'ro',
	coerce      => 1,
);

1;
# ABSTRACT: Cards are approved

__END__

=pod

=head1 NAME

Business::PaperlessTrans::Response::Role::IsApproved - Cards are approved

=head1 VERSION

version 0.002000

=head1 AUTHOR

Caleb Cushing <xenoterracide@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Caleb Cushing.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
