package Bot::IRC::X::Feeds;
# ABSTRACT: Bot::IRC plugin to watch and notify on changes in RSS feeds

use strict;
use warnings;

use XML::RSS;
use LWP::UserAgent;
use LWP::Protocol::https;
use Date::Parse 'str2time';
use WWW::Shorten qw( TinyURL makeashorterlink );

our $VERSION = '1.03'; # VERSION

sub init {
    my ($bot) = @_;
    $bot->load('Store');
    $bot->load('Join');

    $bot->hook(
        {
            to_me => 1,
            text  => qr/
                ^feed[s]?
                \s+(?<action>add|list|remove)
                (?:
                    \s+(?<url>\S+)
                    (?:
                        \s+(?<forums>\S+)
                    )?
                )?
            /x,
        },
        sub {
            my ( $bot, $in, $m ) = @_;
            my @urls = @{ $bot->store->get('urls') || [] };

            if ( $m->{action} eq 'add' ) {
                my $url = lc( $m->{url} );
                if ( grep { $_->{url} eq $url } @urls ) {
                    $bot->reply_to(q{I'm already tracking that feed.});
                }
                else {
                    push( @urls, {
                        url    => $url,
                        forums => [ split( ',', lc $m->{forums} ) ],
                    } );
                    $bot->reply_to(q{OK. I'll report changes from the feed you provided.});
                    $bot->store->set( 'urls' => \@urls );
                }
            }
            elsif ( $m->{action} eq 'list' ) {
                if (@urls) {
                    $bot->reply($_) for ( map {
                        ( @{ $_->{forums} } )
                            ? $_->{url} . ' (' . join( ', ', @{ $_->{forums} } ) . ')'
                            : $_->{url}
                    } @urls );
                }
                else {
                    $bot->reply_to(q{I'm currently not tracking any feeds.});
                }
            }
            elsif ( $m->{action} eq 'remove' ) {
                my $url = lc( $m->{url} );
                if ( $url eq 'all' ) {
                    $bot->reply_to(q{OK. I'll stop reporting on all the feeds I've been tracking.});
                    $bot->store->set( 'urls' => [] );
                }
                elsif ( grep { $_->{url} eq $url } @urls ) {
                    $bot->reply_to(q{OK. I'll stop reporting on the feed you provided.});
                    $bot->store->set( 'urls' => [ grep { $_->{url} ne $url } @urls ] );
                }
                else {
                    $bot->reply_to(qq{I wasn't able to find the feed you specified. ($url)});
                }
            }

            return 1;
        },
    );

    my $ua              = LWP::UserAgent->new;
    my $rss             = XML::RSS->new;
    my $interval        = ( $bot->vars->{interval} || 10 ) * 60;
    my $max_per         = $bot->vars->{max_per} || 5;
    my $fresh_intervals = $bot->vars->{fresh_intervals} || 2;

    $bot->tick(
        $interval,
        sub {
            my ($bot) = @_;

            my $seen     = $bot->store->get('seen') || {};
            my $now      = time;
            my $since    = $now - $interval * $fresh_intervals;
            my $channels = $bot->channels;

            for ( keys %$seen ) {
                delete $seen->{$_} if ( $seen->{$_} < $since );
            }

            for my $url ( @{ $bot->store->get('urls') || [] } ) {
                my $res = $ua->get( $url->{url} );
                next unless ( $res->is_success );

                eval {
                    $rss->parse( $res->decoded_content );
                };
                if ($@) {
                    warn $@;
                    next;
                }

                my $printed = 0;
                for my $item ( @{ $rss->{items} } ) {
                    my $time = str2time(
                        ( $item->{dc} and $item->{dc}{date} ) ? $item->{dc}{date} : $item->{pubDate}
                    );
                    next if ( not $time or $time < $since );

                    my $key = join( '|',
                        $url->{url},
                        $item->{title},
                        $item->{link},
                        $time,
                    );
                    next if ( $seen->{$key} );
                    $seen->{$key} = $now;

                    my $msg =
                        'Feed: ' . $rss->channel('title') .
                        ' [ ' . $item->{title} . ' ]' .
                        ' (' . makeashorterlink( $item->{link} ) . ')';
                    $msg .= ' -- ' . $item->{comments} if ( $item->{comments} );

                    $bot->msg( $_, $msg ) for ( ( @{ $url->{forums} } ) ? @{ $url->{forums} } : @$channels );

                    last if ( ++$printed >= $max_per );
                }
            }

            $bot->store->set( 'seen' => $seen );
        },
    );

    $bot->helps( feeds =>
        'Watch and notify on changes in RSS feeds. ' .
        'Usage: bot feed add URL [FORUMS], bot feed list, bot feed remove URL. ' .
        'See also: https://metacpan.org/pod/Bot::IRC::X::Feeds'
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bot::IRC::X::Feeds - Bot::IRC plugin to watch and notify on changes in RSS feeds

=head1 VERSION

version 1.03

=for markdown [![Build Status](https://travis-ci.org/gryphonshafer/Bot-IRC-X-Feeds.svg)](https://travis-ci.org/gryphonshafer/Bot-IRC-X-Feeds)
[![Coverage Status](https://coveralls.io/repos/gryphonshafer/Bot-IRC-X-Feeds/badge.png)](https://coveralls.io/r/gryphonshafer/Bot-IRC-X-Feeds)

=head1 SYNOPSIS

    use Bot::IRC;

    Bot::IRC->new(
        connect => { server => 'irc.perl.org' },
        plugins => ['Feeds'],
        vars    => {
            x-feeds => {
                interval        => 10,
                max_per         => 5,
                fresh_intervals => 2,
            }
        },
    )->run;

=head1 DESCRIPTION

This L<Bot::IRC> plugin adds functionality so bots can watch and notify on
changes in RSS feeds. You can tell the bot to start following feeds.

    bot feed add URL [FORUMS]

You can optionally provide a "FORUMS" string, which is a list of channels the
bot should report on for the feed. By default, the bot reports on all channels
it has joined. (Requires the L<Bot::IRC::Join> plugin.) The list of channels
must be comma-delimited with no spaces.

You can list the feeds the bot is following:

    bot feed list

And you can remove feeds from being watched:

    bot feed remove URL

You can also remove all feeds from being watched:

    bot feed remove all

=head2 Configuration Settings

Setting the C<x-feeds> values allows for configuration.

    Bot::IRC->new(
        connect => { server => 'irc.perl.org' },
        plugins => ['Feeds'],
        vars    => {
            x-feeds => {
                interval        => 10,
                max_per         => 5,
                fresh_intervals => 2,
            }
        },
    )->run;

The "interval" value is the time interval between calls to feeds, measured in
minutes.

The "max_per" value is the number of items returned per feed per call.

The "fresh_intervals" setting means how many intervals of time backward should
items be considered fresh enough to report on. For example, if you set an
interval of 5 minutes and a fresh_intervals of 3, then any item in a feed with
a publication time older than 15 will not be reported.

The default values for all are shown in the example above.

=head1 SEE ALSO

You can look for additional information at:

=over 4

=item *

L<Bot::IRC>

=item *

L<GitHub|https://github.com/gryphonshafer/Bot-IRC-X-Feeds>

=item *

L<CPAN|http://search.cpan.org/dist/Bot-IRC-X-Feeds>

=item *

L<MetaCPAN|https://metacpan.org/pod/Bot::IRC::X::Feeds>

=item *

L<AnnoCPAN|http://annocpan.org/dist/Bot-IRC-X-Feeds>

=item *

L<Travis CI|https://travis-ci.org/gryphonshafer/Bot-IRC-X-Feeds>

=item *

L<Coveralls|https://coveralls.io/r/gryphonshafer/Bot-IRC-X-Feeds>

=item *

L<CPANTS|http://cpants.cpanauthors.org/dist/Bot-IRC-X-Feeds>

=item *

L<CPAN Testers|http://www.cpantesters.org/distro/T/Bot-IRC-X-Feeds.html>

=back

=for Pod::Coverage init

=head1 AUTHOR

Gryphon Shafer <gryphon@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Gryphon Shafer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
