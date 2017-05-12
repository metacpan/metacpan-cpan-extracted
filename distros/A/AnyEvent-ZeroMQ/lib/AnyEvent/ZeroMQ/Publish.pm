package AnyEvent::ZeroMQ::Publish;
BEGIN {
  $AnyEvent::ZeroMQ::Publish::VERSION = '0.01';
}
# ABSTRACT: Non-blocking OO abstraction over ZMQ_PUB publish/subscribe sockets
use Moose;
use MooseX::Aliases;

use true;
use namespace::autoclean;
use ZeroMQ::Raw::Constants qw(ZMQ_PUB);
use Params::Util qw(_CODELIKE);

with 'AnyEvent::ZeroMQ::Role::WithHandle' =>
    { socket_type => ZMQ_PUB, socket_direction => 'w' },
    'MooseX::Traits';

has '+_trait_namespace' => ( default => 'AnyEvent::ZeroMQ::Publish::Trait' );

sub mangle_message {
    my ($self, $msg, %args) = @_;
    warn 'ignoring unused mangle arguments '. join(', ', map { "'$_'" } keys %args)
        if %args;
    return $msg;
}

sub publish {
    my ($self, $msg, %args) = @_;

    if(_CODELIKE($msg)){ # not to be confused with 'if _CATLIKE($tobias)'
        $self->handle->push_write(sub {
            my $txt = $msg->(@_);
            return $self->mangle_message($txt, %args);
        });
    }
    else {
        $self->handle->push_write($self->mangle_message($msg, %args));
    }
}

alias 'push_write' => 'publish';

with 'AnyEvent::ZeroMQ::Handle::Role::Generic',
     'AnyEvent::ZeroMQ::Handle::Role::Writable';

__PACKAGE__->meta->make_immutable;

__END__
=pod

=head1 NAME

AnyEvent::ZeroMQ::Publish - Non-blocking OO abstraction over ZMQ_PUB publish/subscribe sockets

=head1 VERSION

version 0.01

=head1 AUTHOR

Jonathan Rockway <jrockway@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jonathan Rockway.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

