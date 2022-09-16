package App::MonM::QNotifier;
use warnings;
use strict;
use utf8;

=encoding utf-8

=head1 NAME

App::MonM::QNotifier - The MonM Quick Notification Subsystem

=head1 VERSION

Version 1.01

=head1 SYNOPSIS

    use App::MonM::QNotifier;

=head1 DESCRIPTION

This is an extension for the monm notifications

=head2 new

    my $notifier = App::MonM::QNotifier->new(
            config => $app->configobj,
        );

=head2 channel

    my $channel = $notifier->channel;

Returns App::MonM::Channel object

=head2 config

    my $configobj = $notifier->config;

Returns CTK config object

=head2 error

    my $error = $notifier->error;

Returns error string

    $notifier->error( "error text" );

Sets error string

=head2 getChanelsBySendTo

    my @channels = $notifier->getChanelsBySendTo("user1, my@example.com, 123456789");

Resolves the "SendTo" recipients and takes channels for each from it

=head2 getGroups

    my @groups = $notifier->getGroups;

Returns allowed groups

=head2 getUsers

    my @users = $notifier->getUsers;

Returns allowed users

=head2 getUsersByGroup

    my @users = $notifier->getUsersByGroup("wheel");

Returns users of specified group

=head2 notify

    $notifier->notify(
        to      => ['@FooGroup, @BarGroup, testuser, foo@example.com, 11231230002'],
        subject => "Test message",
        message => "Text of test message",
        before => sub {
            my $self = shift; # App::MonM::QNotifier object (this)
            my $message = shift; # App::MonM::Message object

            # ...

            return 1;
        },
        after => sub {
            my $self = shift; # App::MonM::QNotifier object (this)
            my $message = shift; # App::MonM::Message object
            my $sent = shift; # Status of sending

            die ( $self->channel->error ) unless $sent;

            # ...

            return 1;
        },
    ) or die($notifier->error);

Sends message (text of message) to recipients list

The callback function "before" calls before the message sending. Must be return the true value.
The callback function "after" calls after the message sending. Must be return the true value

=head2 remind

Tries to send postponed messages

=head1 HISTORY

See C<Changes> file

=head1 TO DO

See C<TODO> file

=head1 SEE ALSO

L<App::MonM::Notifier>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<https://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2022 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use vars qw/$VERSION/;
$VERSION = '1.01';

use CTK::Util qw//;
use CTK::ConfGenUtil;
use CTK::TFVals qw/ :ALL /;
use App::MonM::Util qw/parsewords merge/;
use App::MonM::Channel;
use App::MonM::Message;

use constant {
    TIMEOUT         => 20, # 20 sec timeout
};

sub new {
    my $class = shift;
    my %args = @_;
    $args{config} ||= {};

    # Get actual user list
    my $user_conf = $args{config}->conf('user') || {};
    my @users = ();
    foreach my $u (keys %$user_conf) {
        next unless value($user_conf => $u, "enable") || value($user_conf => $u, "enabled");
        push @users, $u;
    }

    # Get actual group list
    my $group_conf = $args{config}->conf('group') || {};
    my @groups = ();
    foreach my $g (keys %$group_conf) {
        next unless value($group_conf => $g, "enable") || value($group_conf => $g, "enabled");
        push @groups, $g;
    }

    # Get group users (hash of arrays)
    my %group;
    foreach my $g (@groups) {
        my $gusers = array($group_conf, $g, "user") || [];
        my @grpusers = qw//;
        foreach my $u (@$gusers) {
            my @words = parsewords($u);
            push @grpusers, grep {value($user_conf => $_, "enable") || value($user_conf => $_, "enabled")} @words;
        }
        $group{$g} = [(CTK::Util::_uniq(@grpusers))];
    }

    # Get Channel defaults
    my $channels_def = hash($args{config}->conf('channel')) || {};

    # Channel object
    my $channel = App::MonM::Channel->new;

    my $self = bless {
            error   => '',
            users   => [(CTK::Util::_uniq(@users))], # Allowed users
            groups  => [(CTK::Util::_uniq(@groups))], # Allowed groups
            group   => {%group}, # group => [users]
            config  => $args{config},
            ch_def  => $channels_def,
            channel => $channel,
        }, $class;

    return $self;
}

sub error {
    my $self = shift;
    my $value = shift;
    return uv2null($self->{error}) unless defined($value);
    return $self->{error} = $value;
}
sub config {
    my $self = shift;
    $self->{config};
}
sub channel {
    my $self = shift;
    $self->{channel};
}
sub getUsers {
    my $self = shift;
    my $users = $self->{users} || [];
    return @$users;
}
sub getGroups {
    my $self = shift;
    my $groups = $self->{groups} || [];
    return @$groups;
}
sub getUsersByGroup {
    my $self = shift;
    my $group = shift;
    return () unless $group;
    my $users = array($self->{group}, $group);
    return @$users;
}
sub getChanelsBySendTo {
    my $self = shift;
    my $rcpts_in = shift || [];

    # Get rcpts
    my @rcpts_noresolved;
    foreach my $it (@$rcpts_in) {
        my @words = parsewords($it);
        push @rcpts_noresolved, @words;
    }

    # Resolve all rcpts
    my @users = ($self->getUsers);
    my %rcpts = (); # user => notation
    foreach my $it (@rcpts_noresolved) {
        next unless $it;
        if ($it =~ /^\@(\w+)/) {
            my @us = $self->getUsersByGroup($1);
            foreach my $u (@us) {
                $rcpts{$u} = "user";
            }
        } elsif ($it =~ /\@/) {
            $rcpts{$it} = "email"; # E-Mail (simple notation)
        } elsif ($it =~ /^[\(+]*\d+/) {
            $it =~ s/[^0-9]//g;
            $rcpts{$it} = "number";
        } else {
            $rcpts{$it} = "user" if grep {$_ eq $it} @users;
        }
    }

    # Get Channels
    my @channels = (); # Channel config sections
    foreach my $it (keys %rcpts) {
        my $notat = $rcpts{$it};
        if ($notat eq 'user') {
            # Get User node
            my $usernode = node($self->config->conf("user"), $it);
            next unless is_hash($usernode) && keys %$usernode;

            # Get channels
            my $channels_usr = hash($usernode => "channel");
            foreach my $ch_name (keys %$channels_usr) {
                my $at = lvalue($channels_usr, $ch_name, "at") || lvalue($usernode, "at");
                my $basedon = lvalue($channels_usr, $ch_name, "basedon") || lvalue($channels_usr, $ch_name, "baseon") || '';
                my $ch = merge(
                    hash($self->{ch_def}, $basedon || $ch_name),
                    hash($channels_usr, $ch_name),
                    {$at ? (at => $at) : ()},
                );
                $ch->{chname} = $ch_name;
                push @channels, $ch;
            }
        } elsif ($notat eq 'email') {
            my $ch = merge(hash($self->{ch_def}, "SendMail"), {to => $it});
            $ch->{chname} = "SendMail";
            push @channels, $ch;
        } elsif ($notat eq 'number') {
            my $ch = merge(hash($self->{ch_def}, "SMSGW"), {to => $it});
            $ch->{chname} = "SMSGW";
            push @channels, $ch;
        }
    }

    return (@channels);
}

sub notify { # send message to recipients list
    my $self = shift;
    my %args = @_;
    $self->error("");
    my $before = $args{before}; # The callback for before sending
    my $after = $args{after}; # The callback for after sending
    my @channels = $self->getChanelsBySendTo(array($args{to}));

    # Create messages and send its
    foreach my $ch (@channels) {
        #print App::MonM::Util::explain($ch);
        my $message = App::MonM::Message->new(
            to          => lvalue($ch, "to"),
            cc          => lvalue($ch, "cc"),
            bcc         => lvalue($ch, "bcc"),
            from        => lvalue($ch, "from"),
            subject     => $args{subject} // '', # Message subject
            body        => $args{message} // '', # Message body
            headers     => hash($ch, "headers"),
            contenttype => lvalue($ch, "contenttype"), # optional
            charset     => lvalue($ch, "charset"), # optional
            encoding    => lvalue($ch, "encoding"), # optional
            attachment  => node($ch, "attachment"),
        );

        # Run before callback
        if (ref($before) eq 'CODE') {
            &$before($self, $message) or next;
        }

        # Send message
        my $sent = $self->channel->sendmsg($message, $ch);

        # Run after callback
        if (ref($after) eq 'CODE') {
            &$after($self, $message, $sent) or next;
        }
    }

    # returns status of operation
    return 1;
}

sub remind { # tries to send postponed messages
    my $self = shift;
    $self->error("");
    return 1;
}

1;

__END__
