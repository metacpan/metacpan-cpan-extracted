package AnyEvent::ZeroMQ::Request;
BEGIN {
  $AnyEvent::ZeroMQ::Request::VERSION = '0.01';
}
# ABSTRACT: Non-blocking OO abstraction over ZMQ_REQ request/reply sockets
use Moose;
use true;
use namespace::autoclean;
use ZeroMQ::Raw::Constants qw(ZMQ_REQ);

with 'AnyEvent::ZeroMQ::Role::WithHandle' =>
    { socket_type => ZMQ_REQ, socket_direction => '' };

sub push_request {
    my ($self, $req, $handler, $hint) = @_;
    if(defined $hint){
        $self->handle->push_read(sub {
            $handler->(@_, $hint);
        });
    }
    else {
        $self->handle->push_read($handler);
    }
    $self->handle->push_write($req);
}

with 'AnyEvent::ZeroMQ::Handle::Role::Generic';

__PACKAGE__->meta->make_immutable;

__END__
=pod

=head1 NAME

AnyEvent::ZeroMQ::Request - Non-blocking OO abstraction over ZMQ_REQ request/reply sockets

=head1 VERSION

version 0.01

=head1 AUTHOR

Jonathan Rockway <jrockway@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jonathan Rockway.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

