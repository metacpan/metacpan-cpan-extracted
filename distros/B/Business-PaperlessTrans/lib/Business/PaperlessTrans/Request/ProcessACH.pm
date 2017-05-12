package Business::PaperlessTrans::Request::ProcessACH;
use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.002000'; # VERSION

use Moose;
use MooseX::Types::Common::String qw( NumericCode );

extends 'Business::PaperlessTrans::Request';

with qw(
	Business::PaperlessTrans::Request::Role::Profile
	Business::PaperlessTrans::Request::Role::Money
);

sub _build_type {
	return 'ProcessACH';
}

has check => (
	remote_name => 'Check',
	isa         => 'Business::PaperlessTrans::RequestPart::Check',
	is          => 'ro',
);

has check_number => (
	remote_name => 'CheckNumber',
	isa         => NumericCode,
	is          => 'ro',
);

__PACKAGE__->meta->make_immutable;
1;
# ABSTRACT: AuthorizeCard Request

__END__

=pod

=head1 NAME

Business::PaperlessTrans::Request::ProcessACH - AuthorizeCard Request

=head1 VERSION

version 0.002000

=head1 AUTHOR

Caleb Cushing <xenoterracide@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Caleb Cushing.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
