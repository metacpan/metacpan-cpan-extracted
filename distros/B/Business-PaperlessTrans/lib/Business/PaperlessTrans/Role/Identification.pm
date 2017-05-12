package Business::PaperlessTrans::Role::Identification;
use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.002000'; # VERSION

use Moose::Role;
use MooseX::RemoteHelper;

has identification => (
	remote_name => 'Identification',
	isa         => 'Business::PaperlessTrans::RequestPart::Identification',
	is          => 'ro',
);

1;
# ABSTRACT: Identification

__END__

=pod

=head1 NAME

Business::PaperlessTrans::Role::Identification - Identification

=head1 VERSION

version 0.002000

=head1 AUTHOR

Caleb Cushing <xenoterracide@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Caleb Cushing.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
