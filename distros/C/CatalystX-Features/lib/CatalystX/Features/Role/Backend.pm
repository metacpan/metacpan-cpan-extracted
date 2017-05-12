package CatalystX::Features::Role::Backend;
$CatalystX::Features::Role::Backend::VERSION = '0.26';
use Moose::Role;

requires 'init';
requires 'list';
requires 'get';
requires 'me';

=head1 NAME

CatalystX::Features::Role::Backend - Role for implementing a backend.

=head1 VERSION

version 0.26

=head1 DESCRIPTION

This role is an interface. No code here.

=head1 REQUIRED METHODS

=head2 init

Gets called by the main L<CatalystX::Features> plugin during C<use Catalyst qw/.../> phase.

=head2 list

Returns a list of available features, all of them L<CatalystX::Features::Role::Feature> objects.

=head2 me 

Returns and instance of L<CatalystX::Features::Role::Feature> corresponding to the feature from which it's being called.  

=head2 get

Given a feature name (say C<my.simple.feature>) returns the feature object. 

=head1 AUTHORS

	Rodrigo de Oliveira (rodrigolive), C<rodrigolive@gmail.com>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify it under
the same terms as Perl itself.

=cut 

1;
