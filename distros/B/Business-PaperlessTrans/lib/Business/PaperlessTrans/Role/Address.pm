package Business::PaperlessTrans::Role::Address;
use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.002000'; # VERSION

use Moose::Role;
use MooseX::RemoteHelper;

has address => (
	isa         => 'Business::PaperlessTrans::RequestPart::Address',
	is          => 'ro',
	remote_name => 'Address',
);

1;
# ABSTRACT: State

__END__

=pod

=head1 NAME

Business::PaperlessTrans::Role::Address - State

=head1 VERSION

version 0.002000

=head1 AUTHOR

Caleb Cushing <xenoterracide@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Caleb Cushing.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
