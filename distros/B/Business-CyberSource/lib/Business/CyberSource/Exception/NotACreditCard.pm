package Business::CyberSource::Exception::NotACreditCard;
use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.010008'; # VERSION

use Moose;
extends 'Business::CyberSource::Exception';

sub _build_message {
	return 'not a credit card';
}

__PACKAGE__->meta->make_immutable;
1;
# ABSTRACT: Card number is not a valid credit card

__END__

=pod

=encoding UTF-8

=head1 NAME

Business::CyberSource::Exception::NotACreditCard - Card number is not a valid credit card

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
