package Bot::IRC::Join;
# ABSTRACT: Bot::IRC join and part channels and remember channels state

use 5.012;
use strict;
use warnings;

our $VERSION = '1.25'; # VERSION

sub init {
    my ($bot) = @_;
    $bot->load('Store');

    $bot->hook(
        {
            to_me => 1,
            text  => qr/^join\s+(?<channel>\S+)/i,
        },
        sub {
            my ( $bot, $in, $m ) = @_;

            if ( $m->{channel} =~ /^#\w+$/ ) {
                $bot->reply( 'I will attempt to join: ' . $m->{channel} );
                $bot->join( $m->{channel} );
            }
            else {
                $bot->reply_to( '"' . $m->{channel} . q{" doesn't appear to be a channel I can join.} );
            }
        },
    );

    $bot->hook(
        {
            to_me => 1,
            text  => qr/^(?:part|leave)\s+(?<channel>\S+)/i,
        },
        sub {
            my ( $bot, $in, $m ) = @_;

            if ( $m->{channel} =~ /^#\w+$/ ) {
                $bot->reply_to( 'I will depart: ' . $m->{channel} );
                $bot->part( $m->{channel} );
            }
            else {
                $bot->reply_to( '"' . $m->{channel} . q{" doesn't appear to be a valid channel name.} );
            }
        },
    );

    $bot->hook(
        {
            to_me => 1,
            text  => qr/^channels\b/i,
        },
        sub {
            my ($bot)    = @_;
            my @channels = @{ $bot->store->get('channels') || [] };

            $bot->reply_to(
                (@channels)
                    ? 'I am currently in the following channels: ' .
                        $bot->list( ', ', 'and', sort { $a cmp $b } @channels ) . '.'
                    : 'I am currently not in any channels.'
            );
        },
    );

    $bot->helps( join => 'Join and part channels. Usage: join <channel>, part <channel>, channels.' );

    {
        no strict 'refs';
        for ( qw( join part ) ) {
            my $name = ref($bot) . '::' . $_;
            *{ $name . '_super' } = *$name{CODE};
        }
    }

    $bot->subs(
        join => sub {
            my $bot      = shift;
            my @channels = @_;
            my %channels = map { $_ => 1 } @{ $bot->store->get('channels') || [] };
            @channels    = keys %channels unless (@channels);

            my $join = $bot->settings('connect')->{join};
            if ( not @channels and $join ) {
                @channels = ( ref $join eq 'ARRAY' ) ? @$join : $join
            }

            $bot->join_super(@channels);

            $channels{$_} = 1 for (@channels);
            $bot->store->set( 'channels' => [ keys %channels ] );

            return $bot;
        },
    );

    $bot->subs(
        part => sub {
            my $bot      = shift;
            my %channels = map { $_ => 1 } @{ $bot->store->get('channels') || [] };

            $bot->part_super(@_);

            delete $channels{$_} for (@_);
            $bot->store->set( 'channels' => [ keys %channels ] );

            return $bot;
        },
    );

    $bot->subs(
        channels => sub {
            return shift->store->get('channels') || [];
        },
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bot::IRC::Join - Bot::IRC join and part channels and remember channels state

=head1 VERSION

version 1.25

=head1 SYNOPSIS

    use Bot::IRC;

    Bot::IRC->new(
        connect => { server => 'irc.perl.org' },
        plugins => ['Join'],
    )->run;

=head1 DESCRIPTION

This L<Bot::IRC> plugin handles messages instructing the bot to join or
part channels. Tell the bot to join and part channels as such:

=head2 join <channel>

Join a given channel.

=head2 part <channel>

Depart a given channel.

=head2 SEE ALSO

L<Bot::IRC>

=for Pod::Coverage init

=head1 AUTHOR

Gryphon Shafer <gryphon@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Gryphon Shafer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
