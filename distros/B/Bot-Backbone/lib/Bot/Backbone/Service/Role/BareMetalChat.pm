package Bot::Backbone::Service::Role::BareMetalChat;
$Bot::Backbone::Service::Role::BareMetalChat::VERSION = '0.161950';
use v5.10;
use Moose::Role;

with 'Bot::Backbone::Service::Role::Chat';

# ABSTRACT: A chat service that is bolted on to bare metal


has _message_queue => (
    is          => 'rw',
    isa         => 'ArrayRef',
    required    => 1,
    default     => sub { [] },
    traits      => [ 'Array' ],
    handles     => {
        '_enqueue_message'     => 'push',
        #'_empty_message_queue' => [ map => sub { undef $_ } ],
        '_empty_message_queue' => 'clear',
    },
);

after shutdown => sub {
    my $self = shift;
    for my $timer (@{ $self->_message_queue }) {
        undef $timer;
    }
    $self->_message_queue([]);
    #$self->_empty_message_queue;
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bot::Backbone::Service::Role::BareMetalChat - A chat service that is bolted on to bare metal

=head1 VERSION

version 0.161950

=head1 DESCRIPTION

This role is nearly identical to L<Bot::Backbone::Service::Role::Chat>, but is
used to mark a chat service as one that will perform the final sending of a
message to an external service (e.g., L<Bot::Backbone::Service::JabberChat> or
L<Bot::Backbone::Service::ConsoleChat>) rather than one that just does some
internal routing (e.g., L<Bot::Backbone::Service::GroupChat> or
L<Bot::Backbone::Service::DirectChat>).

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
