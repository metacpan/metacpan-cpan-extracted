package Business::CyberSource::Role::Traceable;
use strict;
use warnings;

our $VERSION = '0.010008'; # VERSION

use Moose::Role;
use MooseX::SetOnce;

our @CARP_NOT = ( 'Class::MOP::Method::Wrapped', __PACKAGE__ );

has http_trace => (
	isa       => 'XML::Compile::SOAP::Trace',
	predicate => 'has_http_trace',
	traits    => [ 'SetOnce' ],
	is        => 'rw',
	writer    => '_http_trace',
);

sub trace { return $_[0]->http_trace } ## no critic ( RequireArgUnpacking RequireFinalReturn )
sub has_trace { return $_[0]->has_http_trace } ## no critic ( RequireArgUnpacking RequireFinalReturn )

before [qw( trace has_trace ) ] => sub {
	my $self = shift;
	warnings::warnif('deprecated', # this is due to Moose::Exception conflict
		'`trace` is deprecated call `http_trace` instead'
	) unless $self->isa('Moose::Exception');
};

1;
# ABSTRACT: provides http_trace

__END__

=pod

=encoding UTF-8

=head1 NAME

Business::CyberSource::Role::Traceable - provides http_trace

=head1 VERSION

version 0.010008

=head1 METHODS

=head2 trace

aliased to L</http_trace>

=head2 has_trace

aliased to L</has_http_trace>

=head1 ATTRIBUTES

=head2 http_trace

A L<XML::Compile::SOAP::Trace> object which is populated only after the object
has been submitted to CyberSource by a L<Business::CyberSource::Client>.

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
