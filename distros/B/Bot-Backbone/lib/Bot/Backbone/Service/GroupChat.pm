package Bot::Backbone::Service::GroupChat;
$Bot::Backbone::Service::GroupChat::VERSION = '0.161950';
use v5.10;
use Bot::Backbone::Service;

with qw(
    Bot::Backbone::Service::Role::Service
    Bot::Backbone::Service::Role::Dispatch
    Bot::Backbone::Service::Role::Chat
);

with 'Bot::Backbone::Service::Role::ChatConsumer' => {
    -excludes => [ 'send_message' ],
};

with_bot_roles qw(
    Bot::Backbone::Bot::Role::GroupChat
);

# ABSTRACT: A helper chat for performing group chats


has group => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
);


has nickname => (
    is          => 'ro',
    isa         => 'Str',
    predicate   => 'has_nickname',
);


sub initialize {
    my $self = shift;

    my %options = (
        group => $self->group,
    );

    $options{nickname} = $self->nickname if $self->has_nickname;

    $self->chat->join_group(\%options);
}


sub send_message {
    my ($self, $params) = @_;
    my $text = $params->{text};
    $self->chat->send_message({
        group => $self->group,
        text  => $text,
    });
}


sub receive_message {
    my ($self, $message) = @_;

    return unless $message->is_group
              and $message->group eq $self->group;

    $self->resend_message($message);
    $self->dispatch_message($message);
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bot::Backbone::Service::GroupChat - A helper chat for performing group chats

=head1 VERSION

version 0.161950

=head1 SYNOPSIS

  service group_foo => (
      service => 'GroupChat',
      chat    => 'jabber_chat',
      group   => 'foo',
  );

=head1 DESCRIPTION

This is a chat consumer that provides chat services to a specific group on the
consumed chat service.

=head1 ATTRIBUTES

=head2 group

This is the name of the group this chat will communicate with. It will not
perform chats in any other group or directly.

=head2 nickname

This is the nickname to pass to the chat when joining the group. If not set, no
special nickname will be requested.

=head1 METHODS

=head2 initialize

Joins the L</group>.

=head2 send_message

Sends a message to the L</group>.

=head2 receive_message

If the message belongs to the L</group> this chat service works with, the
consumers will be notified and the dispatcher run. Otherwise, the message will
be ignored.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
