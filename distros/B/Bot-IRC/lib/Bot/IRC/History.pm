package Bot::IRC::History;
# ABSTRACT: Bot::IRC selected channel history dumped to email

use 5.014;
use exact;

use Date::Format 'time2str';
use Date::Parse 'str2time';
use Email::Mailer;
use Email::Valid;
use File::Grep 'fgrep';

our $VERSION = '1.42'; # VERSION

sub init {
    my ($bot)       = @_;
    my $vars        = $bot->vars;
    my @filter      = ( ref $vars->{filter} ) ? @{ $vars->{filter} } : ( $vars->{filter} );
    my $stdout_file = $bot->settings('daemon')->{stdout_file};

    $bot->hook(
        {
            to_me => 1,
            text  => qr/
                ^\s*history\s+(
                    (?:
                        (?<type>on)\s+(?<date>.+?)
                    ) |
                    (?:
                        (?<type>from)\s+(?<date>.+?)\s+to\s+(?<date2>.+?)
                    ) |
                    (?:
                        (?<type>matching)\s+(?<string>.+?)
                    )
                )\s+(?:to\s+)?(?<email>\S+)\s*$
            /ix,
        },
        sub {
            my ( $bot, $in, $m ) = @_;

            if ( not $in->{forum} ) {
                $bot->reply_to(q{Ask me from within a specific channel.});
            }
            elsif ( grep { lc( $in->{forum} ) eq lc($_) } @filter ) {
                $bot->reply_to(q{I'm not allowed to return history for this channel.});
            }
            elsif ( not Email::Valid->address( $m->{email} ) ) {
                $bot->reply_to('The email address you provided does not appear to be valid.');
            }
            elsif ( not -f $stdout_file ) {
                $bot->reply_to(q{Sorry. I can't seem to access a log file right now.});
            }
            elsif ( $m->{date} and not $m->{time_date} = str2time( $m->{date} ) ) {
                $bot->reply_to(qq{I don't understand "$m->{date}" as a date or date/time.});
            }
            elsif ( $m->{date2} and not $m->{time_date2} = str2time( $m->{date2} ) ) {
                $bot->reply_to(qq{I don't understand "$m->{date2}" as a date or date/time.});
            }
            else {
                $bot->reply_to('Searching history...');

                my @matches =
                    map {
                        my $matches = $_->{matches};
                        map { $matches->{$_} } sort { $a <=> $b } keys %$matches;
                    } fgrep {
                        /^\[[^\]]*\]\s\S+\sPRIVMSG\s$in->{forum}/
                    } $stdout_file;

                my $subject;
                if ( lc $m->{type} eq 'on' ) {
                    my $date = time2str( '%d/%b/%Y', $m->{time_date} );
                    my $re   = qr/^\[$date/;
                    @matches = grep { $_ =~ $re } @matches;
                    $subject = "on date $m->{date}";
                }
                elsif ( lc $m->{type} eq 'from' ) {
                    @matches =
                        map { $_->{text} }
                        grep {
                            $_->{time} >= $m->{time_date} and
                            $_->{time} <= $m->{time_date2}
                        }
                        map {
                            /^\[([^\]]+)\]\s/;
                            +{
                                time => str2time($1),
                                text => $_,
                            };
                        } @matches;
                    $subject = "from $m->{date} to $m->{date2}";
                }
                elsif ( lc $m->{type} eq 'matching' ) {
                    @matches = grep { /$m->{string}/i } @matches;
                    $subject = "matching $m->{string}";
                }

                if ( not @matches ) {
                    $bot->reply_to(q{I didn't find any history matching what you requested.});
                }
                else {
                    my $html = join( "\n", map {
                        /^\[(?<timestamp>[^\]]+)\]\s(?:\:(?<nick>[^!]+)!)?.*?PRIVMSG\s$in->{forum}\s:(?<text>.+)$/;
                        my $parts = {%+};
                        $parts->{nick} //= 'ME';

                        qq{
                            <p style="text-indent: -3em; margin: 0; margin-left: 3em">
                                <i>$parts->{timestamp}</i>
                                <b>$parts->{nick}</b>
                                $parts->{text}
                            </p>
                        };
                    } @matches );

                    $html =~ s|(\w+://[\w\-\.!@#$%^&*-_+=;:,]+)|<a href="$1">$1</a>|g;

                    Email::Mailer->send(
                        to      => $m->{email},
                        from    => $m->{email},
                        subject => "IRC $in->{forum} history $subject",
                        html    => $html,
                    );

                    $bot->reply_to(
                        'OK. I just sent ' . $m->{email} . ' an email with ' .
                        scalar(@matches) . ' matching history lines.'
                    );
                }
            }
        },
    );

    $bot->helps( history =>
        'Dump selected channel history to email. ' .
        'Usage: "history on DATE EMAIL" or "history from DATE to DATE EMAIL" or "history matching STRING EMAIL".'
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bot::IRC::History - Bot::IRC selected channel history dumped to email

=head1 VERSION

version 1.42

=head1 SYNOPSIS

    use Bot::IRC;

    Bot::IRC->new(
        connect => { server => 'irc.perl.org' },
        plugins => ['History'],
        history => { filter => ['#perl'] },
    )->run;

=head1 DESCRIPTION

This L<Bot::IRC> plugin gives the bot the capability to dump channel chat
history to an email.

The bot will only dump history from which the request originates. If you are
currently in a channel, the bot will happily dump you anything from that
channel's history, even prior to your joining. The idea here being that if
you've got access to join a channel, you have access to that channel's history.

If you don't like this behavior, don't load this plugin.

=head2 Requesting History

To request channel history for the channel you're currently in:

    bot history on DATE EMAIL
    bot history from DATE to DATE EMAIL
    bot history matching STRING EMAIL

=head2 Filtering Channels

You can specify the channels to filter or disallow from history with C<vars>,
C<history>, C<filter>, which can be either a string or arrayref.

    Bot::IRC->new(
        connect => { server => 'irc.perl.org' },
        plugins => ['History'],
        history => { filter => ['#perl'] },
    )->run;

=head2 SEE ALSO

L<Bot::IRC>

=for Pod::Coverage init

=head1 AUTHOR

Gryphon Shafer <gryphon@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016-2050 by Gryphon Shafer.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
