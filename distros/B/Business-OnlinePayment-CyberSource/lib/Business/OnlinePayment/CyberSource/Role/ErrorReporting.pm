package Business::OnlinePayment::CyberSource::Role::ErrorReporting;

use 5.010;
use strict;
use warnings;
use namespace::autoclean;

use Moose::Role;
use MooseX::StrictConstructor;
use MooseX::Types::Moose qw(Str);
use MooseX::Types::Common::String qw(NonEmptySimpleStr);

# ABSTRACT:  Error reporting role for BOP::CyberSource
our $VERSION = '3.000016'; # VERSION

#### Subroutine Definitions ####

#### Object Attributes ####

has error          => (
	isa       => Str,
	is        => 'rw',
	required  => 0,
	predicate => 'has_errors',
	clearer   => 'clear_error',
	reader    => 'error_message',
	writer    => 'set_error_message',
	init_arg  => undef,
	lazy      => 0,
);

has failure_status => (
	isa       => Str,
	is        => 'rw',
	required  => 0,
	predicate => 'has_failure_status',
	clearer   => 'clear_failure_status',
	init_arg  => undef,
	lazy      => 0,
);

1;

__END__

=pod

=head1 NAME

Business::OnlinePayment::CyberSource::Role::ErrorReporting - Error reporting role for BOP::CyberSource

=head1 VERSION

version 3.000016

=head1 SYNOPSIS

  package Thing;

  use Moose;

  with 'Business::OnlinePayment::CyberSource::Role::ErrorReporting';
  1;

  my $thing = Thing->new();

  if ( $thing->has_errors() ) {
	  my $errors = $thing->errors();
	}

=head1 DESCRIPTION

This role provides consumers with an errors array attribute and supporting methods.

=head1 METHODS

=head2 has_errors

=head2 has_response_status

=head2 error_message

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
