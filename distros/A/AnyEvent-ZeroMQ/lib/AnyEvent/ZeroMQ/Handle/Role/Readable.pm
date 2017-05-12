package AnyEvent::ZeroMQ::Handle::Role::Readable;
BEGIN {
  $AnyEvent::ZeroMQ::Handle::Role::Readable::VERSION = '0.01';
}
# ABSTRACT: be a readable handle
use Moose::Role;
use true;
use namespace::autoclean;

requires 'on_read';
requires 'clear_on_read';
requires 'has_on_read';
requires 'push_read';

__END__
=pod

=head1 NAME

AnyEvent::ZeroMQ::Handle::Role::Readable - be a readable handle

=head1 VERSION

version 0.01

=head1 AUTHOR

Jonathan Rockway <jrockway@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jonathan Rockway.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

