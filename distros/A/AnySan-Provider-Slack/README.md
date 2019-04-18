# NAME

AnySan::Provider::Slack - AnySan provider for Slack

**THE SOFTWARE IS ALPHA QUALITY. API MAY CHANGE WITHOUT NOTICE.**

# SYNOPSIS

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

# AUTHOR

Ichinose Shogo &lt;shogo82148@gmail.com >

# SEE ALSO

[AnySan](https://metacpan.org/pod/AnySan), [AnyEvent::IRC::Client](https://metacpan.org/pod/AnyEvent::IRC::Client), [Slack API](https://api.slack.com/)

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
