package Business::CyberSource::Response::Role::DCC;
use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.010008'; # VERSION

use Moose::Role;
with qw(
	Business::CyberSource::Role::ForeignCurrency
);

has dcc_supported => (
	required => 1,
	is       => 'ro',
	isa      => 'Bool'
);

has valid_hours => (
	required => 1,
	is       => 'ro',
	isa      => 'Int',
);

has margin_rate_percentage => (
	required => 1,
	is       => 'ro',
	isa      => 'Num',
);

1;

# ABSTRACT: Role that provides attributes specific to responses for DCC

__END__

=pod

=encoding UTF-8

=head1 NAME

Business::CyberSource::Response::Role::DCC - Role that provides attributes specific to responses for DCC

=head1 VERSION

version 0.010008

=head1 ATTRIBUTES

=head2 dcc_supported

=head2 valid_hours

=head2 margin_rate_percentage

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/hostgator/business-cybersource/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Caleb Cushing <xenoterracide@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Caleb Cushing <xenoterracide@gmail.com>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
