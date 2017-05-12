package Business::CyberSource::Response::Role::ReasonCode;
use strict;
use warnings;
use namespace::autoclean;
use Module::Load qw( load );

our $VERSION = '0.010008'; # VERSION

use Moose::Role;
use MooseX::RemoteHelper;
use MooseX::Types::Common::String 0.001005 qw( NumericCode );

has reason_code => (
	isa         => NumericCode,
	remote_name => 'reasonCode',
	required    => 1,
	is          => 'ro',
	predicate   => 'has_reason_code',
);

1;
# ABSTRACT: Role for ReasonCode

__END__

=pod

=encoding UTF-8

=head1 NAME

Business::CyberSource::Response::Role::ReasonCode - Role for ReasonCode

=head1 VERSION

version 0.010008

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
