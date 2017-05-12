package Bot::Backbone::Service::DirectChat;
$Bot::Backbone::Service::DirectChat::VERSION = '0.161950';
use v5.10;
use Bot::Backbone::Service;

with qw(
    Bot::Backbone::Service::Role::Service
    Bot::Backbone::Service::Role::Dispatch
    Bot::Backbone::Service::Role::ChatConsumer
);

with 'Bot::Backbone::Service::Role::Chat' => {
    -excludes => [ qw( send_message ) ],
};

# ABSTRACT: A helper for doing direct chats


sub initialize { }


sub send_message {
    my ($self, $params) = @_;

    my $to = $params->{to} // Bot::Backbone::Identity->new(
        username => $params->{to_username},
        (defined $params->{to_nickname} ? (nickname => $params->{to_nickname}) : ()),
    );

    my $text = $params->{text};

    $self->chat->send_message({
        to   => $to,
        text => $text,
    });
}


sub receive_message {
    my ($self, $message) = @_;

    return unless not $message->is_group
                  and $message->is_direct;

    $self->resend_message($message);
    $self->dispatch_message($message);
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bot::Backbone::Service::DirectChat - A helper for doing direct chats

=head1 VERSION

version 0.161950

=head1 SYNOPSIS

  service private_chat => (
      service => 'DirectChat',
      chat    => 'jabber_chat',
  );

=head1 DESCRIPTION

This is a chat service layered on top of an existing chat service. It only
passes on direct chats received and only sends direct chages back.

=head1 METHODS

=head2 initialize

Does nothing.

=head2 send_message

Sends a direct message chat to the nested chat service.

=head2 receive_message

If the message is not to a group and is sent direct, it will be passed on to
any chat consumers and dispatched.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
