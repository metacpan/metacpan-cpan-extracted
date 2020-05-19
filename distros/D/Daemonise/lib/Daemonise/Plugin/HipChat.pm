package Daemonise::Plugin::HipChat;

use Mouse::Role;

# ABSTRACT: Daemonise HipChat plugin

use LWP::UserAgent;

# severity to message colour mapping
my %colour = (
    debug    => 'gray',
    info     => 'green',
    warning  => 'yellow',
    critical => 'purple',
    error    => 'red',
);


has 'hipchat_url' => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        'https://api.hipchat.com/v1/rooms/message?format=json&auth_token=';
    },
);


has 'hipchat_token' => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
);


has 'hipchat_from' => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => sub { 'Daemonise' },
);


has 'hipchat_room' => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => sub { 'log' },
);


has 'hipchat' => (
    is  => 'rw',
    isa => 'LWP::UserAgent',
);


after 'configure' => sub {
    my ($self, $reconfig) = @_;

    $self->log("configuring HipChat plugin") if $self->debug;

    if (    ref($self->config->{api}) eq 'HASH'
        and ref($self->config->{api}->{hipchat}) eq 'HASH'
        and ref($self->config->{api}->{hipchat}->{token}) eq 'HASH')
    {
        $self->hipchat_token(
            $self->config->{api}->{hipchat}->{token}->{default})
            if defined $self->config->{api}->{hipchat}->{token}->{default};
        $self->hipchat_room($self->config->{api}->{hipchat}->{room})
            if defined $self->config->{api}->{hipchat}->{room};
    }

    # truncate name to 15 characters as that's the limit for the "From" field...
    $self->hipchat_from(substr($self->name, 0, 15));

    $self->hipchat(LWP::UserAgent->new(agent => $self->name));

    return;
};


after 'notify' => sub {
    my ($self, $msg, $room, $severity, $notify_users, $message_format) = @_;

    $msg = '[debug] ' . $msg if $self->debug;

    # fork and to the rest asynchronously
    # $self->async and return;

    my $colour = ($colour{ $severity || 'info' }) || 'green';
    my $res = $self->hipchat->post(
        $self->hipchat_url . $self->hipchat_token, {
            room_id        => $room           || $self->hipchat_room,
            from           => $self->hipchat_from,
            message        => $self->hostname . ': ' . $msg,
            message_format => $message_format || 'text',
            notify         => $notify_users   || 0,
            color          => $colour,
        });

    unless ($res->is_success) {
        $self->log($res->status_line . ': ' . $res->decoded_content);
    }

    # exit; # async
    return;
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Daemonise::Plugin::HipChat - Daemonise HipChat plugin

=head1 VERSION

version 2.13

=head1 SYNOPSIS

    use Daemonise;
    
    my $d = Daemonise->new();
    $d->debug(1);
    $d->foreground(1) if $d->debug;
    $d->config_file('/path/to/some.conf');
    
    $d->load_plugin('HipChat');
    
    $d->configure;
    
    # send a message to the default 'log' channel
    $d->notify("some text");
    
    # send a message to the specified hipchat channel
    $d->notify("some text", 'channel');

=head1 ATTRIBUTES

=head2 hipchat_url

=head2 hipchat_token

=head2 hipchat_from

=head2 hipchat_room

=head2 hipchat

=head1 SUBROUTINES/METHODS provided

=head2 configure

=head2 notify

    Arguments: 

    $msg is the message to send.
    $room is the room to send to.
    $severity is the type of message.
    $notify_users is whether the message will mark the room as having unread messages.
    $message_format indicates the format of the message. "html" or "text".

    More details at https://www.hipchat.com/docs/api/method/rooms/message

=head1 AUTHOR

Lenz Gschwendtner <norbu09@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Lenz Gschwendtner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
