package AnyEvent::ZeroMQ::Pull;
BEGIN {
  $AnyEvent::ZeroMQ::Pull::VERSION = '0.01';
}
# ABSTRACT: Non-blocking OO abstraction over ZMQ_PULL push/pull sockets
use Moose;
use true;
use namespace::autoclean;
use ZeroMQ::Raw::Constants qw(ZMQ_PULL);

with 'AnyEvent::ZeroMQ::Role::WithHandle' =>
    { socket_type => ZMQ_PULL, socket_direction => 'r' };

with 'AnyEvent::ZeroMQ::Handle::Role::Generic',
     'AnyEvent::ZeroMQ::Handle::Role::Readable';

__PACKAGE__->meta->make_immutable;

__END__
=pod

=head1 NAME

AnyEvent::ZeroMQ::Pull - Non-blocking OO abstraction over ZMQ_PULL push/pull sockets

=head1 VERSION

version 0.01

=head1 AUTHOR

Jonathan Rockway <jrockway@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jonathan Rockway.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

