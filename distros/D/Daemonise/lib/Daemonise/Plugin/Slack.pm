package Daemonise::Plugin::Slack;

use Mouse::Role;

# ABSTRACT: Daemonise Slack plugin

use LWP::UserAgent;

# severity to message colour mapping
my %colour = (
    debug    => 'gray',
    info     => 'green',
    warning  => 'yellow',
    critical => 'purple',
    error    => 'red',
);


has 'slack_url' => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => sub { 'https://slack.com/api/chat.postMessage' },
);


has 'slack_token' => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
);


has 'slack_from' => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => sub { 'Daemonise' },
);


has 'slack_room' => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => sub { '#test' },
);


has 'slack' => (
    is  => 'rw',
    isa => 'LWP::UserAgent',
);


after 'configure' => sub {
    my ($self, $reconfig) = @_;

    $self->log("configuring Slack plugin") if $self->debug;

    if (    ref($self->config->{api}) eq 'HASH'
        and ref($self->config->{api}->{slack}) eq 'HASH')
    {
        $self->slack_token($self->config->{api}->{slack}->{token})
            if defined $self->config->{api}->{slack}->{token};
        $self->slack_room($self->config->{api}->{slack}->{room})
            if defined $self->config->{api}->{slack}->{room};
    }

    # truncate name to 15 characters as that's the limit for the "From" field...
    $self->slack_from(substr($self->name, 0, 15));

    $self->slack(LWP::UserAgent->new(agent => $self->name));

    return;
};


after 'notify' => sub {
    my ($self, $msg, $room, $severity, $notify_users, $message_format) = @_;

    $severity = 'info'            unless $severity;
    $room     = $self->slack_room unless $room;
    $room     = '#' . $room       unless ($room =~ /^#/);

    $msg = '[debug] ' . $msg if $self->debug;

    # fork and to the rest asynchronously
    # $self->async and return;

    #Content-type: application/x-www-form-urlencoded
    my $res = $self->slack->post(
        $self->slack_url, {
            token   => $self->slack_token,
            channel => $room || $self->slack_room,
            as_user => $self->slack_from,
            text    => $self->hostname . ': [' . $severity . ']' . $msg,
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

Daemonise::Plugin::Slack - Daemonise Slack plugin

=head1 VERSION

version 2.13

=head1 SYNOPSIS

    use Daemonise;
    
    my $d = Daemonise->new();
    $d->debug(1);
    $d->foreground(1) if $d->debug;
    $d->config_file('/path/to/some.conf');
    
    $d->load_plugin('Slack');
    
    $d->configure;
    
    # send a message to the default 'log' channel
    $d->notify("some text");
    
    # send a message to the specified slack channel
    $d->notify("some text", 'channel');

=head1 ATTRIBUTES

=head2 slack_url

=head2 slack_token

=head2 slack_from

=head2 slack_room

=head2 slack

=head1 SUBROUTINES/METHODS provided

=head2 configure

=head2 notify

    Arguments:

    $msg is the message to send.
    $room is the room to send to.
    $severity is the type of message.
    $notify_users is whether the message will mark the room as having unread messages (ignored for now).
    $message_format indicates the format of the message. "html" or "text" (ignored for now).

    More details at https://www.slack.com/docs/api/method/rooms/message

=head1 AUTHOR

Lenz Gschwendtner <norbu09@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Lenz Gschwendtner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
