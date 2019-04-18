package AnySan::Provider::Slack;
use strict;
use warnings;
our $VERSION = '0.06';

use base 'AnySan::Provider';
our @EXPORT = qw(slack);
use AnySan;
use AnySan::Receive;
use HTTP::Request::Common;
use AnyEvent::HTTP;
use AnyEvent::SlackRTM;
use JSON;
use Encode;

sub slack {
    my(%config) = @_;

    my $self = __PACKAGE__->new(
        client => undef,
        config => \%config,
    );

    # join channels
    my @channels = keys %{ $config{channels} };
    for my $channel (@channels) {
        $self->_call('channels.join', [
            name => $channel,
        ], sub {});
    }

    $self->start;

    return $self;
}

sub metadata { shift->{rtm}->metadata }

sub user {
    my ($self, $id) = @_;
    return $self->{_users}{$id};
}

sub bot {
    my ($self, $id) = @_;
    return $self->{_bots}{$id};
}

sub start {
    my $self = shift;

    my $rtm = AnyEvent::SlackRTM->new($self->{config}{token});
    $rtm->on('hello' => sub {
        # create hash table of users
        my $users = {};
        for my $user (@{$self->metadata->{users}}) {
            $users->{$user->{id}} ||= $user;
            $users->{$user->{name}} ||= $user;
        }
        $self->{_users} = $users;

        my $bots = {};
        for my $bot (@{$self->metadata->{bots}}) {
            $bots->{$bot->{id}} ||= $bot;
            $bots->{$bot->{name}} ||= $bot;
        }
        $self->{_bots} = $bots;
    });
    $rtm->on('message' => sub {
        my ($rtm, $message) = @_;
        my $metadata = $self->metadata or return;
        if ($message->{subtype}) {
            my $filter = $self->{config}{subtypes} || [];
            return unless grep { $_ eq 'all' || $_ eq $message->{subtype} } @$filter;
        }

        # search user nickname
        my $nickname = '';
        my $user_id = encode_utf8($message->{user} || '');
        my $user = $self->user($user_id);
        my $bot = $self->bot($user_id);
        $nickname = $user->{name} if $user;
        $nickname = $bot->{name} if $bot;

        my $receive; $receive = AnySan::Receive->new(
            provider      => 'slack',
            event         => 'message',
            message       => encode_utf8($message->{text} || ''),
            nickname      => encode_utf8($metadata->{self}{name} || ''),
            from_nickname => $nickname,
            attribute     => {
                channel => $message->{channel},
                subtype => $message->{subtype},
                user    => $user,
                bot     => $bot,
            },
            cb            => sub { $self->event_callback($receive, @_) },
        );
        AnySan->broadcast_message($receive);
    });
    $rtm->on('finish' => sub {
        # reconnect
        undef $self->{rtm};
        while (1) {
            eval { $self->start };
            last unless $@;
        }
    });
    $rtm->on('user_change' => sub {
        my ($rtm, $message) = @_;
        my $user = $message->{user};
        my $user_id = $user->{id};

        # remove from cache
        if (my $old_user = $self->{_users}{$user_id}) {
            delete $self->{_users}{$user_id};
            delete $self->{_users}{$old_user->{name}};
        }

        # add new user info to cache
        $self->{_users}{$user_id} = $user;
        $self->{_users}{$user->{name}} = $user;
    });
    $rtm->start;
    $self->{rtm} = $rtm;
}

sub event_callback {
    my($self, $receive, $type, @args) = @_;

    if ($type eq 'reply') {
        $self->_call('chat.postMessage', [
            channel    => $receive->attribute('channel'),
            text       => $args[0],
            as_user    => $self->{config}->{as_user}    ? 'true' : 'false',
            link_names => $self->{config}->{link_names} ? 'true' : 'false',
        ], sub {});
    }
}

sub send_message {
    my($self, $message, %args) = @_;

    $self->_call('chat.postMessage', [
        text       => $message,
        channel    => $args{channel},
        as_user    => $self->{config}->{as_user}    ? 'true' : 'false',
        link_names => $self->{config}->{link_names} ? 'true' : 'false',
        %{ $args{params} || +{} },
    ], sub {});
}

sub _call {
    my ($self, $method, $params, $cb) = @_;
    my $req = POST "https://slack.com/api/$method", [
        token   => $self->{config}{token},
        @$params,
    ];
    my %headers = map { $_ => $req->header($_), } $req->headers->header_field_names;
    my $jd = $self->{json_driver} ||= JSON->new->utf8;
    my $r;
    $r = http_post $req->uri, $req->content, headers => \%headers, sub {
        my $body = shift;
        my $res = $jd->decode($body);
        $cb->($res);
        undef $r;
    };
}

1;
__END__

=head1 NAME

AnySan::Provider::Slack - AnySan provider for Slack

B<THE SOFTWARE IS ALPHA QUALITY. API MAY CHANGE WITHOUT NOTICE.>

=head1 SYNOPSIS

  use AnySan;
  use AnySan::Provider::Slack;
  my $slack = slack(
      token => 'YOUR SLACK API TOKEN',
      channels => {
          'general' => {},
      },

      as_user => 0, # post messages as bot (default)
      # as_user => 1, # post messages as user

      subtypes => [], # ignore all subtypes (default)
      # subtypes => ['bot_message'], # receive messages from bot
      # subtypes => ['all'], # receive all messages(bot_message, me_message, message_changed, etc)
  );
  $slack->send_message('slack message', channel => 'C024BE91L');

  AnySan->register_listener(
      slack => {
          event => 'message',
          cb => sub {
              my $receive = shift;
              return unless $receive->message;
              warn $receive->message;
              warn $receive->attribute->{subtype};
              $receive->send_reply('hogehoge');
          },
      },
  );

=head1 AUTHOR

Ichinose Shogo E<lt>shogo82148@gmail.com E<gt>

=head1 SEE ALSO

L<AnySan>, L<AnyEvent::IRC::Client>, L<Slack API|https://api.slack.com/>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
