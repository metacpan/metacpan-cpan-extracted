package Bot::IRC::X::Reminder;
# ABSTRACT: Bot::IRC plugin for scheduling reminders

use 5.014;
use exact;

use DateTime;
use DateTime::Duration;
use Time::Crontab;

our $VERSION = '1.08'; # VERSION

sub init {
    my ($bot) = @_;
    $bot->load('Store');

    $bot->hook(
        {
            to_me => 1,
            text  => qr/
                ^remind\s+(?<target>\S+)\s+(?<type>at|in|every)\s+
                (?<expr>
                    (?:[\d\*\/\,\-]+\s+){4}[\d\*\/\,\-]+|
                    \d{1,2}:\d{2}\s*[ap]m?|
                    (?:\d+:)+\d+|
                    \d{3,4}
                )
                \s+(?<text>.+)
            /ix,
        },
        sub {
            my ( $bot, $in, $m ) = @_;

            my $target = lc( $m->{target} );
            $target = $in->{nick} if ( $target eq 'me' );

            my ( $expr, $lapse ) = ( '', 0 );
            if ( $m->{expr} =~ /^(\d{1,2}):(\d{2})\s*([ap])m?$/i ) {
                $expr = join( ' ', $2, ( ( lc $3 eq 'a' ) ? $1 + 12 : $1 ), '* * *' );
            }
            elsif ( $m->{expr} =~ /^(\d{1,2})(\d{2})$/ ) {
                $expr = "$2 $1 * * *";
            }
            elsif ( $m->{expr} =~ /^(?:\d+:)*\d+$/ ) {
                my @parts = split( /:/, $m->{expr} );
                shift(@parts) while ( @parts > 6 );
                unshift( @parts, 0 ) while ( @parts < 6 );

                $lapse = DateTime->now->add_duration(
                    DateTime::Duration->new(
                        map { $_ => shift @parts } qw( years months weeks days hours minutes )
                    )
                )->epoch - time();
            }
            else {
                $expr = $m->{expr};
            }

            my @reminders = @{ $bot->store->get('reminders') || [] };
            push( @reminders, {
                author => lc( $in->{nick} ),
                target => $target,
                repeat => ( ( lc( $m->{type} ) eq 'every' ) ? 1 : 0 ),
                text   => $m->{text},
                expr   => $expr,
                time   => ( ($lapse) ? time() + $lapse : undef ),
                lapse  => $lapse,
            } );
            $bot->store->set( 'reminders' => \@reminders );

            $bot->reply_to('OK.');
        },
    );

    $bot->tick(
        '* * * * *',
        sub {
            my ($bot) = @_;
            my @reminders = @{ $bot->store->get('reminders') || [] };
            return unless (@reminders);
            my $reminders_changed = 0;

            @reminders = grep { defined } map {
                $bot->msg( $_->{target}, $_->{text} );
                $_->{time} += $_->{lapse} if ( $_->{time} );
                $reminders_changed = 1 unless ( $_->{repeat} );
                ( $_->{repeat} ) ? $_ : undef;
            }
            grep {
                $_->{time} and $_->{time} <= time() or
                $_->{expr} and Time::Crontab->new( $_->{expr} )->match( time() )
            } @reminders;

            $bot->store->set( 'reminders' => \@reminders ) if ($reminders_changed);
        },
    );

    $bot->hook(
        {
            to_me => 1,
            text  => qr/^reminders\s+(?<command>list|forget)\s+(?<scope>mine|all)\b/i,
        },
        sub {
            my ( $bot, $in, $m ) = @_;
            my @reminders = @{ $bot->store->get('reminders') || [] };

            if ( lc( $m->{command} ) eq 'list' ) {
                if ( lc( $m->{scope} ) eq 'mine' ) {
                    my $me = lc( $in->{nick} );
                    @reminders = grep { $_->{author} eq $me } @reminders;
                }
                $bot->reply_to(
                    'I have no reminders ' . ( ( lc( $m->{scope} ) eq 'mine' ) ? 'from you ' : '' ) . 'on file.'
                ) unless (@reminders);

                for ( my $i = 0; $i < @reminders; $i++ ) {
                    $bot->reply_to(
                        ( $reminders[$i]->{expr} || scalar( localtime( $reminders[$i]->{time} ) ) ) . ' ' .
                        ( ( $reminders[$i]->{repeat} ) ? '(repeating) ' : '' ) .
                        'to ' . $reminders[$i]->{target} .
                        ': ' . $reminders[$i]->{text}
                    );
                    sleep 1 if ( $i + 1 < @reminders );
                }
            }
            else {
                if ( lc( $m->{scope} ) eq 'mine' ) {
                    my $me = lc( $in->{nick} );
                    @reminders = grep { $_->{author} ne $me } @reminders;
                }
                else {
                    @reminders = ();
                }

                $bot->store->set( 'reminders' => \@reminders );
                $bot->reply_to('OK.');
            }

            return 1;
        },
    );

    $bot->helps( reminder =>
        'Set reminders for things. ' .
        'Usage: <bot nick> remind <nick> <every|at|in> <time expr> <reminder text>. ' .
        'See also: https://metacpan.org/pod/Bot::IRC::X::Reminder.'
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bot::IRC::X::Reminder - Bot::IRC plugin for scheduling reminders

=head1 VERSION

version 1.08

=for markdown [![test](https://github.com/gryphonshafer/Bot-IRC-X-Reminder/workflows/test/badge.svg)](https://github.com/gryphonshafer/Bot-IRC-X-Reminder/actions?query=workflow%3Atest)
[![codecov](https://codecov.io/gh/gryphonshafer/Bot-IRC-X-Reminder/graph/badge.svg)](https://codecov.io/gh/gryphonshafer/Bot-IRC-X-Reminder)

=head1 SYNOPSIS

    use Bot::IRC;

    Bot::IRC->new(
        connect => { server => 'irc.perl.org' },
        plugins => ['Reminder'],
    )->run;

=head1 DESCRIPTION

This L<Bot::IRC> plugin is for scheduling reminders. You can ask the bot to
remind someone about something at some future time. If the nick who needs to
be reminded isn't online at the time of the reminder, the reminder isn't issued.

The general format is:

    <bot nick> remind <nick|channel> <every|at|in> <time expr> <reminder text>

If you specify a "nick" of "me", then the bot will remind your nick.

The "every|at|in" is the type of reminder. Each type of reminder requires a
slightly different time expression.

=head2 at

The "at" reminder type requires a time expression in the form of a clock time
or a crontab-looking expression. Clock time expressions are in the form
C<\d{1,2}:\d{2}\s*[ap]m?> for "normal human time" and C<\d{3,4}> for military
time.

    bot remind me at 2:30p This is to remind you of your dentist appointment.
    bot remind hoser at 1620 Hey hoser, it's 4:20 PM now.
    bot remind #team at 0530 Time for someone on the team to make coffee.

Crontab-looking expressions are in the C<* * * * *> form.

    bot remind me at 30 5 * * 1-5 Good morning! It's a great day to code Perl.

Once an "at" reminder type triggers, it's done and won't repeat.

=head2 in

The "in" reminder type requires a number of minutes in the future for when the
reminder should happen. In addition to minutes, you can specify hours, days,
weeks, or whatever.

    bot remind me in 30 It has been half-an-hour since you set this reminder.
    bot remind me in 2:30 It has been 2 hours and 30 minutes.
    bot remind me in 3:0:0 It has been 3 days.
    bot remind me in 1:2:0:0 It has been 1 week and 2 days.

Once an "in" reminder type triggers, it's done and won't repeat.

=head2 every

The "every" reminder type is exactly like the "at" reminder type except that
the reminder repeatedly triggers when the time expression matches.

    bot remind me every 30 5 * * 1-5 Another great day to code Perl.

=head1 HELPER FUNCTIONS

There are a couple of helper functions you can call as well.

=head2 list reminders

You can list all of your reminders or all reminders from anyone.

    bot reminders list mine
    bot reminders list all

=head2 forget reminders

You can tell the bot to forget all of your reminders or all reminders from
everyone.

    bot reminders forget mine
    bot reminders forget all

=head1 SEE ALSO

You can look for additional information at:

=over 4

=item *

L<Bot::IRC>

=item *

L<GitHub|https://github.com/gryphonshafer/Bot-IRC-X-Reminder>

=item *

L<MetaCPAN|https://metacpan.org/pod/Bot::IRC::X::Reminder>

=item *

L<GitHub Actions|https://github.com/gryphonshafer/Bot-IRC-X-Reminder/actions>

=item *

L<Codecov|https://codecov.io/gh/gryphonshafer/Bot-IRC-X-Reminder>

=item *

L<CPANTS|http://cpants.cpanauthors.org/dist/Bot-IRC-X-Reminder>

=item *

L<CPAN Testers|http://www.cpantesters.org/distro/T/Bot-IRC-X-Reminder.html>

=back

=for Pod::Coverage init

=head1 AUTHOR

Gryphon Shafer <gryphon@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016-2050 by Gryphon Shafer.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
