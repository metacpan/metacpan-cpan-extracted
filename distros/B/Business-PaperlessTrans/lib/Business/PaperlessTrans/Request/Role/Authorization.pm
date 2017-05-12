package Business::PaperlessTrans::Request::Role::Authorization;
use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.002000'; # VERSION

use Moose::Role;
use MooseX::RemoteHelper;

with qw(
	Business::PaperlessTrans::Request::Role::Money
);

has card_present => (
	remote_name => 'CardPresent',
	isa         => 'Bool',
	is          => 'ro',
);

has card => (
	remote_name => 'Card',
	isa         => 'Business::PaperlessTrans::RequestPart::Card',
	is          => 'ro',
	required    => 1,
);

1;
# ABSTRACT: Request does Authorization

__END__

=pod

=head1 NAME

Business::PaperlessTrans::Request::Role::Authorization - Request does Authorization

=head1 VERSION

version 0.002000

=head1 AUTHOR

Caleb Cushing <xenoterracide@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Caleb Cushing.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
