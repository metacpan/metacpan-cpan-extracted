package Business::CyberSource::Exception::SOAPFault;
use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.010008'; # VERSION

use Moose;
use MooseX::RemoteHelper;
extends 'Business::CyberSource::Exception';

sub _build_message {
	my $self = shift;
	return $self->faultstring;
}

has $_ => (
	remote_name => $_,
	isa         => 'Str',
	is          => 'ro',
	required    => 1,
) foreach qw( faultstring faultcode );

__PACKAGE__->meta->make_immutable;
1;
# ABSTRACT: CyberSource API threw a SOAP Fault

__END__

=pod

=encoding UTF-8

=head1 NAME

Business::CyberSource::Exception::SOAPFault - CyberSource API threw a SOAP Fault

=head1 VERSION

version 0.010008

=head1 DESCRIPTION

This usually means a credentials problem or something is wrong on
CyberSource's end

=head1 ATTRIBUTES

=head2 faultstring

description of error

=head2 faultcode

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
