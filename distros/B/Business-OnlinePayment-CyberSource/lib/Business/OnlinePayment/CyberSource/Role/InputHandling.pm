package Business::OnlinePayment::CyberSource::Role::InputHandling;

use 5.010;
use strict;
use warnings;
use namespace::autoclean;

use Moose::Role;

# ABSTRACT:  Input handling convenience methods for Business::OnlinePayment::CyberSource
our $VERSION = '3.000016'; # VERSION

#### Subroutine Definitions ####

# Converts input into a hashref
# Accepts:  A hash or reference to a hash
# Returns:  A reference to the supplied hash

sub _parse_input { ## no critic ( Subroutines::ProhibitUnusedPrivateSubroutines )
	my ( undef, @args ) = @_;
	my $data            = {};

	# shift off first element if only one exists and is of type HASH
	if ( scalar @args == 1 && ref $args[0] eq 'HASH' ) {
		$data             = shift @args;
	}
	# Cast into a hash if number of elements is even and first element is a string
	elsif ( ( scalar @args % 2 ) == 0 && ref $args[0] eq '' ) {
		$data             = { @args };
	}

	return $data;
}

1;

__END__

=pod

=head1 NAME

Business::OnlinePayment::CyberSource::Role::InputHandling - Input handling convenience methods for Business::OnlinePayment::CyberSource

=head1 VERSION

version 3.000016

=head1 SYNOPSIS

  package Thing;

  use Moose;

  with 'Business::OnlinePayment::CyberSource::Role::InputHandling';

  sub blah {
  	my ( $self, @args ) = @_;
		my $data = $self->_parse_input( @args );

  	$data->{color} = 'red' unless $data->{color};
  }
	 1;

  my $thing = Thing->new();

  $thing->blah( color => 'blue' );
  $thing->blah( { color => 'blue' } );

=head1 DESCRIPTION

This role provides consumers with convenience methods for handling input.

=head1 METHODS

=head2 _parse_input

Converts input into a hashref

Accepts:  A hash or reference to a hash
Returns:  A reference to the supplied hash

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/xenoterracide/business-onlinepayment-cybersource/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHORS

=over 4

=item *

Jad Wauthier <Jadrien dot Wauthier at GMail dot com>

=item *

Caleb Cushing <xenoterracide@gmail.com>

=item *

Peter Bowen <peter@bowenfamily.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by L<HostGator.com|http://www.hostgator.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
