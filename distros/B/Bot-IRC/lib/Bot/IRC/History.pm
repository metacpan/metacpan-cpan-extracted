package Bot::IRC::History;
# ABSTRACT: Bot::IRC selected channel history dumped to email

use strict;
use warnings;
use Email::Valid;
use Mail::Send;
use File::Grep 'fgrep';

our $VERSION = '1.13'; # VERSION

sub init {
    my ($bot)       = @_;
    my $vars        = $bot->vars;
    my @filter      = ( ref $vars->{filter} ) ? @{ $vars->{filter} } : ( $vars->{filter} );
    my $stdout_file = $bot->settings('daemon')->{stdout_file};

    $bot->hook(
        {
            to_me => 1,
            text  => qr/history\s+(?<search>\S+)\s+(?<email>\S+)/i,
        },
        sub {
            my ( $bot, $in, $m ) = @_;

            if ( grep { lc( $in->{forum} ) eq lc($_) } @filter ) {
                $bot->reply_to(q{I'm not allowed to return history for this channel.});
            }
            elsif ( not Email::Valid->address( $m->{email} ) ) {
                $bot->reply_to('The email address you provided does not appear to be valid.');
            }
            elsif ( not -f $stdout_file ) {
                $bot->reply_to(q{Sorry. I can't seem to access a log file right now.});
            }
            else {
                $bot->reply_to('Searching history...');

                my @matches = map {
                    my $matches = $_->{matches};
                    map { $matches->{$_} } sort { $a <=> $b } keys %$matches;
                } fgrep {
                    /^\[[^\]]*\]\s\S+\sPRIVMSG\s$in->{forum}/ and
                    /$m->{search}/
                } $stdout_file;

                if ( not @matches ) {
                    $bot->reply_to(q{I didn't find any history matching what you requested.});
                }
                else {
                    my $mail = Mail::Send->new(
                        Subject => "IRC $in->{forum} history search: $m->{search}",
                        To      => $m->{email},
                    );
                    $mail->set( 'From' => $m->{email} );

                    my $fh = $mail->open;
                    $fh->print( join( '', @matches ) );
                    $fh->close;

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
        'Usage: "history [DATE] [EMAIL]" or "history [STRING] [EMAIL]". ' .
        'See also: https://metacpan.org/pod/Bot::IRC::History'
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bot::IRC::History - Bot::IRC selected channel history dumped to email

=head1 VERSION

version 1.13

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

    bot history [DATE] [EMAIL]
    bot history 01/Dec/2016 gryphon@example.com

The "date" is any partial date or date/time used in the Common Log Format (CLF).
So to select everything from the hour of 11 AM:

    bot history 01/Dec/2016:11 gryphon@example.com

You can also search for any particular string in the chat history of the
channel:

    bot history string gryphon@example.com

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

This software is copyright (c) 2016 by Gryphon Shafer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
