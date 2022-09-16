package App::MonM::Notifier; # $Id: Notifier.pm 78 2022-09-16 08:22:04Z abalama $
use warnings;
use strict;
use utf8;

=encoding utf-8

=head1 NAME

App::MonM::Notifier - extension for the monm notifications

=head1 VERSION

Version 1.04

=head1 SYNOPSIS

    use App::MonM::QNotifier;

=head1 DESCRIPTION

This is an extension for the monm notifications with guaranteed delivery

=head2 new

    my $notifier = App::MonM::Notifier->new(
            config => $app->configobj,
        );

=head2 notify

    $notifier->notify(
        to      => ['@FooGroup, @BarGroup, testuser, foo@example.com, 11231230002'],
        subject => "Test message",
        message => "Text of test message",
        before => sub {
            my $self = shift; # App::MonM::QNotifier object (this)
            my $message = shift; # App::MonM::Message object

            warn ( $self->error ) if $self->error;

            # ...

            return 1;
        },
        after => sub {
            my $self = shift; # App::MonM::QNotifier object (this)
            my $message = shift; # App::MonM::Message object
            my $sent = shift; # Status of sending

            warn ( $self->error ) if $self->error;

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

=head2 store

    my $store = $notifier->store();

Returns store object

=head1 CONFIGURATION

Example of configuration section:

    UseMonotifier yes
    <MoNotifier>
        File /tmp/monotifier.db
        Expires 1h
        MaxTime 1m
    </MoNotifier>

=head1 HISTORY

See C<Changes> file

=head1 DEPENDENCIES

L<App::MonM::QNotifier>

=head1 TO DO

See C<TODO> file

=head1 BUGS

* none noted

=head1 SEE ALSO

L<App::MonM::QNotifier>

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
$VERSION = '1.04';

use parent qw/App::MonM::QNotifier/;

use CTK::ConfGenUtil;

use App::MonM::Util qw/getExpireOffset parsewords merge/;
use App::MonM::Notifier::Store;

use constant {
    NODE_NAME           => 'notifier',
    NODE_NAME_ALIAS     => 'monotifier',
};

sub new {
    my $class = shift;
    my %args = @_;
    my $self = $class->SUPER::new(%args);

    # Store
    my $store_conf = hash($self->config->conf(NODE_NAME) || $self->config->conf(NODE_NAME_ALIAS));
    $store_conf->{expires} = getExpireOffset(lvalue($store_conf, "expires") || lvalue($store_conf, "expire") || 0);
    $store_conf->{maxtime} = getExpireOffset(lvalue($store_conf, "maxtime") || 0);
    my $store = App::MonM::Notifier::Store->new(%$store_conf);
    $self->{store} = $store;
    #print App::MonM::Util::explain($store);

    return $self;
}
sub store {
    my $self = shift;
    return $self->{store};
}
sub notify { # send message to recipients list
    my $self = shift;
    my %args = @_;
    $self->error("");
    my $before = $args{before}; # The callback for before sending
    my $after = $args{after}; # The callback for after sending
    my @channels = $self->getChanelsBySendTo(array($args{to}));
    my $store = $self->store;

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

        # Enqueue
        my $newid = $store->enqueue(
            to      => lvalue($ch, "to") || lvalue($ch, "recipient") || "anonymous",
            channel => $ch->{chname},
            subject => $args{subject} // '',
            message => $args{message} // '',
            attributes => $ch, # Channel attributes
        );
        $self->error($store->error);

        # Run before callback
        if (ref($before) eq 'CODE') {
            &$before($self, $message) or next;
        }

        # Send message
        my $sent = $self->channel->sendmsg($message, $ch);

        # ReQueue or DeQueue
        if ($newid) {
            if ($sent) { # SENT
                $store->dequeue(
                    id => $newid
                );
            } else { # FAIL (NOT SENT)
                $store->requeue(
                    id => $newid,
                    code => 1, # Notifier Level
                    error => $self->channel->error,
                );
            }
            $self->error($store->error);
        }

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
    my $store = $self->store;

    # Cleanup first
    unless ($store->cleanup) {
        $self->error($store->error || "Can't cleanup store");
        return 0;
    }

    while (my $entity = $store->retrieve) {
        last if $store->error;
        my $id = $entity->{id};
        my $ch = hash($entity, "attributes");
        #print App::MonM::Util::explain($entity);

        # Create message
        my $message = App::MonM::Message->new(
            to          => lvalue($ch, "to"),
            cc          => lvalue($ch, "cc"),
            bcc         => lvalue($ch, "bcc"),
            from        => lvalue($ch, "from"),
            subject     => $entity->{subject},
            body        => $entity->{message},
            headers     => hash($ch, "headers"),
            contenttype => lvalue($ch, "contenttype"), # optional
            charset     => lvalue($ch, "charset"), # optional
            encoding    => lvalue($ch, "encoding"), # optional
            attachment  => node($ch, "attachment"),
        );

        # Send message
        my $sent = $self->channel->sendmsg($message, $ch);

        # ReQueue or DeQueue
        if ($sent) { # SENT
            $store->dequeue( id => $id );
        } else { # FAIL (NOT SENT)
            $store->requeue( id => $id,
                code => 2, # Notifier Level (remind)
                error => $self->channel->error,
            );
        }
    }

    # Set errors
    if ($store->error) {
        $self->error($store->error);
        return 0;
    }

    return 1;
}

1;

__END__
