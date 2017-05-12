package Business::CyberSource::Factory::Rule;
use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.010008'; # VERSION

use MooseX::AbstractFactory;

implementation_class_via sub { 'Business::CyberSource::Rule::' . shift};

__PACKAGE__->meta->make_immutable;
1;
# ABSTRACT: CyberSource Rule Factory Module

__END__

=pod

=encoding UTF-8

=head1 NAME

Business::CyberSource::Factory::Rule - CyberSource Rule Factory Module

=head1 VERSION

version 0.010008

=head1 METHODS

=head2 create

takes the name of an object in C<Business::CyberSource::Rule::> namespace as
the first parameter, then the client object, passed as a hashref to the rule
constructor.

	$factory->create( 'ExpiredCard', { client => $self } ),

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
