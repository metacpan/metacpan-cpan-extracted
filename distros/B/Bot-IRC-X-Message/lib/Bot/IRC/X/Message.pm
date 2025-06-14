package Bot::IRC::X::Message;
# ABSTRACT: Bot::IRC plugin for leaving messages for nicks

use 5.014;
use exact;

use DateTime;
use DateTime::Format::Human::Duration;

our $VERSION = '1.07'; # VERSION

sub init {
    my ($bot) = @_;
    $bot->load('Store');

    $bot->hook(
        {
            to_me => 1,
            text  => qr/^(?:message|tell|ask)\s+(?<nick>\S+)\s+(?<msg>.+)\s*/,
        },
        sub {
            my ( $bot, $in, $m ) = @_;

            my $nick = lc( $m->{nick} );
            my @msgs = @{ $bot->store->get($nick) || [] };

            push( @msgs, {
                in   => $in,
                time => time,
                msg  => $m->{msg},
            } );
            $bot->store->set( $nick => \@msgs );

            $bot->reply_to('OK.');
        },
    );

    my $duration = DateTime::Format::Human::Duration->new;
    $bot->hook(
        {
            command => 'JOIN',
        },
        sub {
            my ( $bot, $in ) = @_;

            my $nick = lc( $in->{nick} );
            my @msgs = @{ $bot->store->get($nick) || [] };

            $bot->store->set( $nick => [] );

            for ( my $i = 0; $i < @msgs; $i++ ) {
                $bot->reply_to(
                    "$msgs[$i]->{in}{nick} left a message for you " .
                    $duration->format_duration_between(
                        map { DateTime->from_epoch( epoch => $_ ) } $msgs[$i]->{time}, time
                    ) .
                    " ago. \"$msgs[$i]->{msg}\""
                );
                sleep 1 if ( $i + 1 < @msgs );
            }

            return;
        },
    );

    $bot->helps( message => 'Leave a message for a nick. Usage: <bot nick> message <target nick> <message>');
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bot::IRC::X::Message - Bot::IRC plugin for leaving messages for nicks

=head1 VERSION

version 1.07

=for markdown [![test](https://github.com/gryphonshafer/Bot-IRC-X-Message/workflows/test/badge.svg)](https://github.com/gryphonshafer/Bot-IRC-X-Message/actions?query=workflow%3Atest)
[![codecov](https://codecov.io/gh/gryphonshafer/Bot-IRC-X-Message/graph/badge.svg)](https://codecov.io/gh/gryphonshafer/Bot-IRC-X-Message)

=head1 SYNOPSIS

    use Bot::IRC;

    Bot::IRC->new(
        connect => { server => 'irc.perl.org' },
        plugins => ['Message'],
    )->run;

=head1 DESCRIPTION

This L<Bot::IRC> plugin provides the means for the bot to keep messages for
nicks.

    <user1> bot message user2 This is a message for you.
    <bot> user1: OK.
    *** user2 has joined #this_channel
    <bot> user2: user1 left a message for you. "This is a message for you."

=head1 SEE ALSO

You can look for additional information at:

=over 4

=item *

L<Bot::IRC>

=item *

L<GitHub|https://github.com/gryphonshafer/Bot-IRC-X-Message>

=item *

L<MetaCPAN|https://metacpan.org/pod/Bot::IRC::X::Message>

=item *

L<GitHub Actions|https://github.com/gryphonshafer/Bot-IRC-X-Message/actions>

=item *

L<Codecov|https://codecov.io/gh/gryphonshafer/Bot-IRC-X-Message>

=item *

L<CPANTS|http://cpants.cpanauthors.org/dist/Bot-IRC-X-Message>

=item *

L<CPAN Testers|http://www.cpantesters.org/distro/T/Bot-IRC-X-Message.html>

=back

=for Pod::Coverage init

=head1 AUTHOR

Gryphon Shafer <gryphon@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016-2050 by Gryphon Shafer.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
