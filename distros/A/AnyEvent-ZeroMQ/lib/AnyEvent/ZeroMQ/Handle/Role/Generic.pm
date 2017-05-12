package AnyEvent::ZeroMQ::Handle::Role::Generic;
BEGIN {
  $AnyEvent::ZeroMQ::Handle::Role::Generic::VERSION = '0.01';
}
# ABSTRACT: stuff both readable and wrtiable handles do
use Moose::Role;
use true;
use namespace::autoclean;

requires 'on_error';
requires 'clear_on_error';
requires 'has_on_error';
requires 'identity';
requires 'has_identity';
requires 'socket';
requires 'bind';
requires 'connect';

__END__
=pod

=head1 NAME

AnyEvent::ZeroMQ::Handle::Role::Generic - stuff both readable and wrtiable handles do

=head1 VERSION

version 0.01

=head1 AUTHOR

Jonathan Rockway <jrockway@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jonathan Rockway.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

