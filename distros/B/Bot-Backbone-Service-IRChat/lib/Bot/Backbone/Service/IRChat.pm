package Bot::Backbone::Service::IRChat;
$Bot::Backbone::Service::IRChat::VERSION = '0.160630';
use v5.10;
use Bot::Backbone::Service;

with qw(
    Bot::Backbone::Service::Role::Service
    Bot::Backbone::Service::Role::Dispatch
    Bot::Backbone::Service::Role::BareMetalChat
    Bot::Backbone::Service::Role::GroupJoiner
);

use Bot::Backbone::Message;
use POE;
use POE::Component::IRC::State;

# ABSTRACT: Connect and chat with an IRC server


has nick => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
);


has server => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
);


has irc => (
    is          => 'ro',
    isa         => 'POE::Component::IRC::State',
    lazy_build  => 1,
);

sub _build_irc {
    my $self = shift;

    return POE::Component::IRC::State->spawn(
        Nick   => $self->nick,
        Server => $self->server,
    );
}


has session_ready => (
    is          => 'rw',
    isa         => 'Bool',
    required    => 1,
    default     => 0,
);


has group_options => (
    is          => 'rw',
    isa         => 'ArrayRef[HashRef]',
    required    => 1,
    default     => sub { [] },
    traits      => [ 'Array' ],
    handles     => {
        all_group_options => 'elements',
        add_group_options => 'push',
    },
);


sub initialize {
    my $self = shift;

    POE::Session->create(
        object_states => [
            $self =>  [ qw(
                _start
                irc_001
                irc_msg
                irc_public
            ) ],
        ],
    );
}


sub _start {
    my $self = $_[OBJECT];

    my $irc = $self->irc;

    $irc->yield('register', qw( 001 msg public ));

    $irc->yield('connect');
}


sub irc_001 {
    my $self = shift;

    if (!$self->session_ready) {
        $self->session_ready(1);
        $self->_join_pending_groups;
    }
}


sub _identity_from_nickhostmask {
    my ($self, $nickhostmask) = @_;

    my ($nick) = $nickhostmask =~ m/^([^!]+)/;
    return Bot::Backbone::Identity->new(
        username => $nickhostmask,
        nickname => $nick,
        me       => 0,
    );
}

sub irc_msg {
    my ($self, $sender, $recipients, $text) = @_[OBJECT, ARG0, ARG1, ARG2];

    my $message = Bot::Backbone::Message->new({
        chat  => $self,
        from  => $self->_identity_from_nickhostmask($sender),
        to    => Bot::Backbone::Identity->new(
            username => $self->nick,
            nickname => $self->nick,
            me       => 1,
        ),
        group => undef,
        text  => $text,
    });

    $self->resend_message($message);
    if ($self->has_dispatcher) {
        $self->dispatch_message($message);
    }
}


sub irc_public {
    my ($self, $sender, $recipients, $text) = @_[OBJECT, ARG0, ARG1, ARG2];

    my $to_identity;
    if ($self->is_to_me($self->nick, \$text)) {
        $to_identity = Bot::Backbone::Identity->new(
            username => $self->nick,
            nickname => $self->nick,
            me       => 1,
        );
    }

    for my $recipient (@$recipients) {
        my $group = $recipient;
           $group =~ s/^#//;

        my $message = Bot::Backbone::Message->new({
            chat   => $self,
            from   => $self->_identity_from_nickhostmask($sender),
            to     => $to_identity,
            group  => $group,
            text   => $text,
            volume => 'spoken',
        });

        $self->resend_message($message);
        $self->dispatch_message($message);
    }
}

sub _join_pending_groups {
    my $self = shift;

    # Perform join from either the params or list of group options
    my @pending_group_options;
    if (@_) {
        @pending_group_options = @_;
    }
    else {
        @pending_group_options = $self->all_group_options;
    }

    my $irc = $self->irc;

    # Join each group requested
    for my $group_options (@pending_group_options) {
        $irc->yield('join', "#$group_options->{group}");
    }
}


sub join_group {
    my ($self, $options) = @_;

    $self->add_group_options($options);
    $self->_join_pending_groups($options) if $self->session_ready;
}


# TODO This code is copied from Bot::Backbone::Service::JabberChat. That's
# pretty naughty. This should be inherent to something else, don'tcha think?
sub is_to_me {
    my ($self, $me_nick, $text) = @_;

    return scalar($$text =~ s/^ $me_nick \s* [:,\-]
                             |  , \s* $me_nick [.!?]? $
                             |  , \s* $me_nick \s* , 
                             //x);
}


sub send_message {
    my ($self, $params) = @_;

    my $to    = $params->{to};
    my $group = $params->{group};
    my $text  = $params->{text};

    my $irc = $self->irc;
    if (defined $group) {
        $irc->yield('privmsg', "#$group", $text);
    }
    else {
        $irc->yield('privmsg', $to, $text);
    }
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bot::Backbone::Service::IRChat - Connect and chat with an IRC server

=head1 VERSION

version 0.160630

=head1 SYNOPSIS

    service irc_chat => (
        service => 'IRChat',
        nick    => 'fancybot',
        server  => 'irc.perl.org',
    );

=head1 DESCRIPTION

Can be used to connect to and chat on Internet Relay Chat servers. Will join channels on the server and communicate with groups that way sa well. It can also speak via private messages.

=head1 ATTRIBUTES

=head2 nick

This is the nickname the bot will take.

=head2 server

This is the hostname of the IRC server to connect.

=head2 irc

This is the internal L<POE::Component::IRC::State> object used to communicate with the server. It is automatically built using the other settings given to this service.

=head2 session_ready

This is a boolean flag that is set to true once the IRC connection is established and the server has started sending messages.

=head2 group_options

This is used to keep track of the channels that the service has been asked to join. These channels will be joined once L</session_ready> is set to true.

=head1 METHODS

=head2 initialize

This starts up the POE session required to connect this service to the event loop.

=head2 _start

When the POE session is setup, this initiates the connection to the IRC server.

=head2 irc_001

This handler is called once the server has started sending messages over the connection and is ready to receive. At this point, L</session_ready> will return true and any channels that need to be joined will be joined.

=head2 irc_msg

This handler is called whenever a privmsg is sent directly to the bot. It passes the message on to the dispatcher and such.

=head2 irc_public

This handler is called whenever a privmsg is sent to a channel that bot has joined. It passes the message on to the dispatcher and such.

=head2 join_group

    $chat->join_group({ group => 'example' });

Joins the group pass to the C<group> option. On IRC, the C<nickname> option is ignored.

=head2 is_to_me

  my $bool = $self->is_to_me($user, \$text);

Given the user that identifies the bot in a group chat and text that was just
sent to the chat, this detects if the message was directed at the bot. Normally,
this includes messages that start with the following:

  nick: ...
  nick, ...
  nick- ...

It also includes suffix references like this:

  ..., nick.
  ..., nick

and infix references like this:

  ..., nick, ...

If you want something different, you may subclass service and override this
method.

Note that the text is sent as a reference and can be modified, usually to remove
the nick from the message so the bot does not have to worry about that.

=head2 send_message

    $chat->send_message( to => 'bob', text => 'hi' );
    $chat->send_message( group => 'example, text => 'hi' );

Call to send a message to the nick, via C<to>, or channel, via C<group>, named.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
