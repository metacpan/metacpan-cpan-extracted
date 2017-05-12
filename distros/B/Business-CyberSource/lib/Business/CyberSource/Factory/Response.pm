package Business::CyberSource::Factory::Response;
use 5.010;
use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.010008'; # VERSION

use Moose;
use Module::Runtime   qw( use_module       );
use Type::Params      qw( compile Invocant );
use Types::Standard   qw( HashRef Optional );
use Type::Utils 0.040 qw( role_type        );

sub create { ## no critic ( RequireArgUnpacking )
	state $traceable = role_type 'Business::CyberSource::Role::Traceable';
	state $check     = compile( Invocant, HashRef, Optional[$traceable]);
	my ( $self, $result , $request ) = $check->( @_ );

	$result->{http_trace}
		= $request->http_trace
		if $request && $request->has_http_trace;

	die ## no critic ( ErrorHandling::RequireCarping )
		use_module('Business::CyberSource::Exception::Response')
		->new( $result ) if $result->{decision} eq 'ERROR';

	return use_module('Business::CyberSource::Response')->new( $result );
}

1;

# ABSTRACT: A Response Factory

__END__

=pod

=encoding UTF-8

=head1 NAME

Business::CyberSource::Factory::Response - A Response Factory

=head1 VERSION

version 0.010008

=head1 METHODS

=head2 create

	my $response = $factory->create( $answer->{result}, $request );

Pass the C<answer->{result}> from L<XML::Compile::SOAP> and the original Request Data
Transfer Object. Passing a L<Business::CyberSource::Request> is now optional.

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
