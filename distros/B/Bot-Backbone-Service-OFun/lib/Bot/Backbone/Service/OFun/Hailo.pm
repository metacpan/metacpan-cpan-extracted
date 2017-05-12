package Bot::Backbone::Service::OFun::Hailo;
$Bot::Backbone::Service::OFun::Hailo::VERSION = '0.142230';
use Bot::Backbone::Service;

with qw(
    Bot::Backbone::Service::Role::Service
    Bot::Backbone::Service::Role::Responder
);

use MooseX::Types::Path::Class;
use Hailo;

# ABSTRACT: Talk to your bot and it talks back


service_dispatcher as {
    to_me spoken respond_by_method 'learn_and_reply';
    also not_command spoken not_to_me run_this_method 'learn';
};


has brain_file => (
    is          => 'ro',
    isa         => 'Path::Class::File',
    required    => 1,
    coerce      => 1,
);


has hailo => (
    is          => 'ro',
    isa         => 'Hailo',
    lazy_build  => 1,
);

sub _build_hailo {
    my $self = shift;

    my $brain_file = $self->brain_file;
    return Hailo->new(
        brain => "$brain_file",
    );
}


sub learn_and_reply {
    my ($self, $message) = @_;
    return $self->hailo->learn_reply($message->text);
}


sub learn {
    my ($self, $message) = @_;
    return $self->hailo->learn($message->text);
}


sub initialize { }

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bot::Backbone::Service::OFun::Hailo - Talk to your bot and it talks back

=head1 VERSION

version 0.142230

=head1 SYNOPSIS

    # in your bot config
    service hailo => (
        service    => 'OFun::Hailo',
        brain_file => 'hailo.db',
    );

    dispatcher chatroom => as {
        redispatch_to 'hailo';
    };

    # in chat
    alice> bot, how are you today?
    bot> That depends on how they are today.

=head1 DESRIPTION

This uses the L<Hailo> library to grant your bot the ability to talk back when spoken to. Used by itself, the bot won't be a very interesting conversationalist at first. Mostly, it will just repeat back to you what you say to it. Over time, however, it will slowly build up a statistical model that will allow it to respond with text that makes very little sense, but sounds like the sorts of things you talk about in your chat room.

If you want to, you can also pre-train it using L<Hailo> library directly and then start of with conversations built on whatever corpus of text you want to start from. I recommend corporate marketing materials or development documentation for maximum entertainment value.

=head1 DISPATCHER

=head2 Any conversation

All conversations that are held in the chat room that are not directed to the bot and do not contain commands for the bot will be used to teach the bot's markov chain data structure.

=head2 Any conversation directed to the bot

Any conversation that is directed at the bot itself in ways common to chat rooms (or any non-command in a direct chat), will result it he bot learning from that conversation and responding to it.

=head1 ATTRIBUTES

=head2 brain_file

This is a path to a file to use as the brain for the bot. See L<Hailo> for information on what goes into this file.

=head2 hailo

This is the C<Hailo> object used to learn and reply to conversation. This is automatically built.

=head1 METHODS

=head2 learn_and_reply

Handles all conversation directed to the bot.

=head2 learn

Handles all other conversation the bot hears.

=head2 initialize

No op.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
