package Business::CyberSource::Exception;
use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.010008'; # VERSION

use Moose;
extends 'Moose::Exception';

our @CARP_NOT = ( 'Class::MOP::Method::Wrapped', __PACKAGE__ );

has value => (
	isa     => 'Int',
	is      => 'ro',
	lazy    => 1,
	default => 0,
);

before value => sub {
		warnings::warnif('deprecated',
			'method `value` is deprecated as Exception::Base is no longer in use'
		);
};

__PACKAGE__->meta->make_immutable;
1;
# ABSTRACT: base exception

__END__

=pod

=encoding UTF-8

=head1 NAME

Business::CyberSource::Exception - base exception

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
